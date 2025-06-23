<?php
error_log("=== GET PROFILE DEBUG START ===");
error_log("REQUEST_METHOD: " . ($_SERVER['REQUEST_METHOD'] ?? 'NOT SET'));
error_log("CONTENT_TYPE: " . ($_SERVER['CONTENT_TYPE'] ?? 'not set'));
error_log("REQUEST_URI: " . ($_SERVER['REQUEST_URI'] ?? 'not set'));
error_log("HTTP_HOST: " . ($_SERVER['HTTP_HOST'] ?? 'not set'));
error_log("HTTP_ORIGIN: " . ($_SERVER['HTTP_ORIGIN'] ?? 'not set'));
error_reporting(E_ALL);
ini_set('display_errors', 1);

require '../vendor/autoload.php';
use Firebase\JWT\JWT as FirebaseJWT;
use Firebase\JWT\Key as FirebaseKey;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use Firebase\JWT\BeforeValidException;

$jwt_secret_key = "your_super_secret_jwt_key_that_is_long_and_random_1234567890abcdef";

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-Csrf-Token");
header("Access-Control-Allow-Credentials: true");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    error_log("GET_PROFILE: Handling OPTIONS preflight request");
    http_response_code(200);
    exit();
}

$host = "localhost";
$user = "root";
$password_db = "";
$db_name = "librareads";

$conn = new mysqli($host, $user, $password_db, $db_name);

if ($conn->connect_error) {
    error_log("GET_PROFILE: Database connection failed: " . $conn->connect_error);
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Server error: Failed to connect to database."]);
    exit;
}

$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

error_log("GET_PROFILE: Authorization header: " . ($authHeader ? '[PRESENT]' : '[MISSING]'));

if (empty($authHeader) || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
    error_log("GET_PROFILE: Authorization token not provided or invalid format");
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Authorization token not provided or invalid format."]);
    $conn->close();
    exit;
}

$jwt_token = $matches[1];
$userId = null;

try {
    $decoded = FirebaseJWT::decode($jwt_token, new FirebaseKey($jwt_secret_key, 'HS256'));
    $userId = $decoded->user_id;
    
    error_log("GET_PROFILE: Decoded JWT payload - user_id: " . ($userId ?? 'NULL') . ", username: " . ($decoded->username ?? 'NULL'));

    if (time() > $decoded->exp) {
        error_log("GET_PROFILE: JWT token expired for user ID: " . $userId);
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Authorization token has expired. Please login again."]);
        $conn->close();
        exit;
    }

    error_log("GET_PROFILE: JWT authentication successful for user ID: " . $userId);

} catch (ExpiredException $e) {
    error_log("GET_PROFILE: Expired token: " . $e->getMessage());
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Authorization token has expired. Please login again."]);
    $conn->close();
    exit;
} catch (SignatureInvalidException $e) {
    error_log("GET_PROFILE: Invalid signature: " . $e->getMessage());
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Invalid authorization token signature."]);
    $conn->close();
    exit;
} catch (BeforeValidException $e) {
    error_log("GET_PROFILE: Token not yet valid: " . $e->getMessage());
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Authorization token not yet valid."]);
    $conn->close();
    exit;
} catch (Exception $e) {
    error_log("GET_PROFILE: Generic JWT decode error: " . $e->getMessage());
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Invalid or expired authorization token: " . $e->getMessage()]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT id, username, email, profile_picture FROM users WHERE id = ?");
if (!$stmt) {
    error_log("GET_PROFILE: Failed to prepare statement: " . $conn->error);
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Server error: Failed to prepare statement."]);
    $conn->close();
    exit;
}
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $username = $row['username'];
    $email = $row['email'];
    $profilePictureNumber = $row['profile_picture'];

    http_response_code(200);
    echo json_encode([
        "status" => "success",
        "user_id" => (int)$userId,
        "username" => $username,
        "email" => $email,
        "profile_picture_url" => (string)$profilePictureNumber
    ]);

    error_log("GET_PROFILE: Success response sent for user ID: " . $userId . " with avatar number: " . $profilePictureNumber);

} else if ($result->num_rows === 0) {
    error_log("GET_PROFILE: User not found for ID: " . $userId);
    http_response_code(404);
    echo json_encode(["status" => "error", "message" => "User profile not found for the authenticated token."]);
} else {
    error_log("GET_PROFILE: Multiple users found for ID: " . $userId);
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Server error: Multiple users found for the same ID."]);
}

$stmt->close();
$conn->close();
error_log("=== GET PROFILE DEBUG END ===");
?>