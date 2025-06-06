<?php
session_start();
include 'db_config.php';

// Memastikan pengguna sudah login
if (!isset($_SESSION['user_id'])) {
    echo json_encode(['status' => 'error', 'message' => 'Unauthorized']);
    exit();
}

$user_id = $_SESSION['user_id'];

// Query untuk mengambil data profil
$sql = "SELECT username, email, profile_picture FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

// Menampilkan hasil dalam format JSON
if ($user) {
    $response = [
        'status' => 'success',
        'username' => $user['username'],
        'email' => $user['email'],
        'profile_picture' => $user['profile_picture'] ? 'uploads/profile_pictures/' . $user['profile_picture'] : null,
    ];
} else {
    $response = [
        'status' => 'error',
        'message' => 'User not found',
    ];
}

echo json_encode($response);
?>
