<?php
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    header("Access-Control-Allow-Origin: *");
    header("Access-Control-Allow-Headers: Content-Type");
    header("Access-Control-Allow-Methods: POST, OPTIONS");
    exit(0);
}

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include 'db_config.php';

$input = json_decode(file_get_contents('php://input'), true);

$username = $conn->real_escape_string($input['username'] ?? '');
$email = $conn->real_escape_string($input['email'] ?? '');
$password = $input['password'] ?? '';
$profile_picture = '';

// Validasi sederhana
if (!$username || !$email || !$password) {
    echo json_encode(['status' => false, 'message' => 'Username, email, dan password wajib diisi']);
    exit;
}

// Cek email sudah ada atau belum
$sqlCheck = "SELECT id FROM users WHERE email = '$email' LIMIT 1";
$resultCheck = $conn->query($sqlCheck);

if ($resultCheck && $resultCheck->num_rows > 0) {
    echo json_encode(['status' => false, 'message' => 'Email sudah terdaftar']);
    exit;
}

// Hash password
$passwordHash = password_hash($password, PASSWORD_DEFAULT);

// Insert ke database
$sqlInsert = "INSERT INTO users (username, email, password, profile_picture) VALUES ('$username', '$email', '$passwordHash', '$profile_picture')";

if ($conn->query($sqlInsert) === TRUE) {
    echo json_encode(['status' => true, 'message' => 'Registrasi berhasil']);
} else {
    echo json_encode(['status' => false, 'message' => 'Error saat registrasi: ' . $conn->error]);
}


$conn->close();
?>
