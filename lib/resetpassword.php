<?php
ini_set('display_errors', 0);
error_reporting(0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/error_log.txt');

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => false, 'message' => 'Metode request tidak diizinkan.']);
    exit;
}

$host = "localhost";
$user = "root";
$password = "";
$db = "librareads";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    error_log("Database connection failed in resetpassword.php: " . $conn->connect_error);
    echo json_encode(['status' => false, 'message' => 'Terjadi masalah pada server. Mohon coba lagi nanti.']);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
$token = $data['token'] ?? '';
$new_password = $data['password'] ?? '';

if (!$token) {
    echo json_encode(['status' => false, 'message' => 'Token tidak valid atau hilang.']);
    $conn->close();
    exit;
}

if (!$new_password) {
    echo json_encode(['status' => false, 'message' => 'Password baru diperlukan.']);
    $conn->close();
    exit;
}

if (strlen($new_password) < 6) {
    echo json_encode(['status' => false, 'message' => 'Password minimal harus 6 karakter.']);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT user_id, expires_at FROM forgotpassword WHERE token = ?");
$stmt->bind_param("s", $token);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    echo json_encode(['status' => false, 'message' => 'Token tidak valid atau sudah tidak berlaku.']);
    $conn->close();
    exit;
}

$user = $result->fetch_assoc();
$user_id = $user['user_id'];
$expiry = $user['expires_at'];
$current_time = date('Y-m-d H:i:s');
if ($current_time > $expiry) {
    $stmt_delete = $conn->prepare("DELETE FROM forgotpassword WHERE token = ?");
    $stmt_delete->bind_param("s", $token);
    $stmt_delete->execute();
    $stmt_delete->close();
    echo json_encode(['status' => false, 'message' => 'Token telah kedaluwarsa. Mohon minta token baru.']);
    $conn->close();
    exit;
}

$hashed_password = password_hash($new_password, PASSWORD_DEFAULT);
$stmt_update = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
$stmt_update->bind_param("si", $hashed_password, $user_id);

if ($stmt_update->execute()) {
    $stmt_delete_success = $conn->prepare("DELETE FROM forgotpassword WHERE token = ?");
    $stmt_delete_success->bind_param("s", $token);
    $stmt_delete_success->execute();
    $stmt_delete_success->close();

    echo json_encode(['status' => true, 'message' => 'Password berhasil diubah!']);
} else {
    error_log("Failed to update password for user_id $user_id: " . $stmt_update->error);
    echo json_encode(['status' => false, 'message' => 'Gagal mengubah password.']);
}
$stmt_update->close();
$conn->close();
?>