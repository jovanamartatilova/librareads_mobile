<?php
error_log("=== LOGIN DEBUG START ===");
error_log("REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD']);
error_log("CONTENT_TYPE: " . ($_SERVER['CONTENT_TYPE'] ?? 'not set'));
error_log("REQUEST_URI: " . ($_SERVER['REQUEST_URI'] ?? 'not set'));
error_log("HTTP_HOST: " . ($_SERVER['HTTP_HOST'] ?? 'not set'));
error_log("HTTP_ORIGIN: " . ($_SERVER['HTTP_ORIGIN'] ?? 'not set'));

error_reporting(E_ALL);
ini_set('display_errors', 1);

require '../vendor/autoload.php';
use Firebase\JWT\JWT as FirebaseJWT;
use Firebase\JWT\Key as FirebaseKey;

$jwt_secret_key = "your_super_secret_jwt_key_that_is_long_and_random_1234567890abcdef";

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");
header("Access-Control-Allow-Credentials: false");
header("Access-Control-Max-Age: 86400");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    error_log("LOGIN: Handling OPTIONS preflight request");
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("LOGIN: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    echo json_encode(["status" => "error", "message" => "Only POST method is allowed for login."]);
    exit;
}

$host = "localhost";
$user = "root";
$password_db = "";
$db_name = "librareads";

$conn = new mysqli($host, $user, $password_db, $db_name);

if ($conn->connect_error) {
    error_log("LOGIN: Database connection failed: " . $conn->connect_error);
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]);
    exit;
}

$username = null;
$password = null;

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
error_log("LOGIN: Content-Type: " . $contentType);

if (strpos($contentType, 'multipart/form-data') !== false) {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    error_log("LOGIN: Form-data input - Username: " . $username);
} elseif (strpos($contentType, 'application/json') !== false) {
    $json_input = file_get_contents('php://input');
    $data = json_decode($json_input, true);
    $username = $data['username'] ?? '';
    $password = $data['password'] ?? '';
    error_log("LOGIN: JSON input - Username: " . $username);
} else {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    if (empty($username) || empty($password)) {
        $json_input = file_get_contents('php://input');
        $data = json_decode($json_input, true);
        $username = $data['username'] ?? '';
        $password = $data['password'] ?? '';
    }
    error_log("LOGIN: Fallback input - Username: " . $username);
}

if (empty($username) || empty($password)) {
    error_log("LOGIN: Missing credentials - Username: '" . $username . "', Password: " . (empty($password) ? '[EMPTY]' : '[PROVIDED]'));
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Username and password are required."]);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT id, username, email, password, profile_picture FROM users WHERE username = ?");
if (!$stmt) {
    error_log("LOGIN: Failed to prepare statement: " . $conn->error);
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error occurred."]);
    $conn->close();
    exit;
}

$stmt->bind_param("s", $username);

if (!$stmt->execute()) {
    error_log("LOGIN: Failed to execute statement: " . $stmt->error);
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Database error occurred."]);
    $stmt->close();
    $conn->close();
    exit;
}

$result = $stmt->get_result();

if ($result && $result->num_rows === 1) {
    $user_data = $result->fetch_assoc();
    $stored_password = $user_data['password'];

    if (password_verify($password, $stored_password)) {
        $user_id = $user_data['id'];
        $username_db = $user_data['username'];
        $email = $user_data['email'];
        $profile_picture = $user_data['profile_picture'];
        
        error_log("LOGIN: Authentication successful for user ID: " . $user_id);

        $payload = [
            'user_id' => (int)$user_id,
            'username' => $username_db,
            'iat' => time(),
            'exp' => time() + (7 * 24 * 60 * 60)
        ];

        $jwt_token = FirebaseJWT::encode($payload, $jwt_secret_key, 'HS256');
        $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
        $host_name = $_SERVER['HTTP_HOST'];
        $baseUploadPath = "$protocol://$host_name/librareadsmob/uploads/";
        
        $profilePictureUrl = null;
        if ($profile_picture !== null && !empty(trim($profile_picture))) {
            $profilePictureUrl = $baseUploadPath . $profile_picture;
            error_log("LOGIN: Profile picture URL: " . $profilePictureUrl);
        } else {
            error_log("LOGIN: No profile picture for user");
        }

        http_response_code(200);
        echo json_encode([
            "status" => "success",
            "message" => "Login successful",
            "token" => $jwt_token,
            "user_id" => (int)$user_id,
            "username" => $username_db,
            "email" => $email,
            "profile_picture_url" => $profilePictureUrl
        ]);
        
        error_log("LOGIN: Success response sent for user ID: " . $user_id);
        
    } else {
        error_log("LOGIN: Invalid password for username: " . $username);
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Invalid username or password."]);
    }
} else {
    error_log("LOGIN: Username not found: " . $username);
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Invalid username or password."]);
}

$stmt->close();
$conn->close();
error_log("=== LOGIN DEBUG END ===");
?>