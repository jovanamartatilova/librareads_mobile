<?php
require '../vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
$jwt_secret_key = "your_super_secret_jwt_key_that_is_long_and_random_1234567890abcdef";

error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-Csrf-Token");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = "localhost";
$user = "root";
$password_db = "";
$db_name = "librareads";
$conn = new mysqli($host, $user, $password_db, $db_name);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "status" => "error",
        "message" => "Server error: Failed to connect to database."
    ]);
    exit;
}

$headers = getallheaders();
$authHeader = '';

foreach ($headers as $key => $value) {
    if (strtolower($key) === 'authorization') {
        $authHeader = $value;
        break;
    }
}

if (empty($authHeader) || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "status" => "error", 
        "message" => "Authorization token not provided or invalid format."
    ]);
    $conn->close();
    exit;
}

$jwt_token = $matches[1];
$sessionUserId = null;

try {
    $decoded = JWT::decode($jwt_token, new Key($jwt_secret_key, 'HS256'));
    $sessionUserId = $decoded->user_id;

    if (time() > $decoded->exp) {
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "status" => "error", 
            "message" => "Authorization token has expired. Please login again."
        ]);
        $conn->close();
        exit;
    }

} catch (Exception $e) {
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "status" => "error", 
        "message" => "Invalid or expired authorization token: " . $e->getMessage()
    ]);
    $conn->close();
    exit;
}
$input_data = json_decode(file_get_contents('php://input'), true);

if (empty($input_data)) {
    $input_data = $_POST;
}

$input_username = isset($input_data['username']) ? trim($input_data['username']) : null;
$input_email = isset($input_data['email']) ? trim($input_data['email']) : null;
$input_profile_picture_url = isset($input_data['profile_picture_url']) ? trim($input_data['profile_picture_url']) : null; 
$input_userId_from_body = isset($input_data['user_id']) ? (int)$input_data['user_id'] : null;
if ($input_userId_from_body === null || $input_userId_from_body !== (int)$sessionUserId) {
    http_response_code(403);
    echo json_encode([
        "success" => false,
        "status" => "error", 
        "message" => "Forbidden: User ID mismatch or missing user_id in request body."
    ]);
    $conn->close();
    exit;
}

$updateFields = [];
$bindParams = "";
$bindValues = [];
if ($input_username !== null) { 
    $updateFields[] = "username = ?";
    $bindParams .= "s";
    $bindValues[] = $input_username;
}

if ($input_email !== null) {
    if (!empty($input_email) && !filter_var($input_email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "status" => "error", 
            "message" => "Invalid email format."
        ]);
        $conn->close();
        exit;
    }
    $updateFields[] = "email = ?";
    $bindParams .= "s";
    $bindValues[] = $input_email;
}

if ($input_profile_picture_url !== null) {
    if (!ctype_digit($input_profile_picture_url) || (int)$input_profile_picture_url < 1 || (int)$input_profile_picture_url > 10) {
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "status" => "error", 
            "message" => "Invalid profile picture number. Must be a digit between 1 and 10."
        ]);
        $conn->close();
        exit;
    }
    $updateFields[] = "profile_picture = ?";
    $bindParams .= "s";
    $bindValues[] = $input_profile_picture_url;
}

if (empty($updateFields)) {
    $currentDataStmt = $conn->prepare("SELECT username, email, profile_picture FROM users WHERE id = ?");
    $currentDataStmt->bind_param("i", $sessionUserId);
    $currentDataStmt->execute();
    $currentResult = $currentDataStmt->get_result();
    $currentData = $currentResult->fetch_assoc();
    $currentDataStmt->close();

    $profilePictureFileName = $currentData['profile_picture'] ?? '1';
    if (empty(trim($profilePictureFileName))) {
        $profilePictureFileName = '1';
    }

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "No changes detected or nothing to update. Returning current profile.",
        "data" => [
            "user_id" => (int)$sessionUserId,
            "username" => $currentData['username'] ?? null,
            "email" => $currentData['email'] ?? null,
            "profile_picture_url" => $profilePictureFileName
        ]
    ]);
    $conn->close();
    exit;
}

$sql = "UPDATE users SET " . implode(", ", $updateFields) . " WHERE id = ?";
$bindParams .= "i";
$bindValues[] = $sessionUserId;

$stmt = $conn->prepare($sql);
if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "status" => "error", 
        "message" => "Server error: Failed to prepare statement. " . $conn->error
    ]);
    $conn->close();
    exit;
}

$refs = [];
foreach ($bindValues as $key => $value) {
    $refs[$key] = &$bindValues[$key];
}
call_user_func_array([$stmt, 'bind_param'], array_merge([$bindParams], $refs));

if ($stmt->execute()) {
    $updatedDataStmt = $conn->prepare("SELECT username, email, profile_picture FROM users WHERE id = ?");
    $updatedDataStmt->bind_param("i", $sessionUserId);
    $updatedDataStmt->execute();
    $updatedResult = $updatedDataStmt->get_result();
    $updatedData = $updatedResult->fetch_assoc();
    $updatedDataStmt->close();

    $profilePictureFileName = $updatedData['profile_picture'] ?? '1';
    if (empty(trim($profilePictureFileName))) {
        $profilePictureFileName = '1';
    }

    echo json_encode([
        "success" => true,
        "status" => "success",
        "message" => "Profile updated successfully.",
        "data" => [
            "user_id" => (int)$sessionUserId,
            "username" => $updatedData['username'] ?? null,
            "email" => $updatedData['email'] ?? null,
            "profile_picture_url" => $profilePictureFileName
        ]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "status" => "error", 
        "message" => "Server error: Failed to execute update. " . $stmt->error 
    ]);
}

$stmt->close();
$conn->close();
?>