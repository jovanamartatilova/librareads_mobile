<?php
// Menampilkan semua error sebagai JSON
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");

// Koneksi ke database
$host = "localhost";
$user = "root";
$password = "";
$db = "librareads";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Connection failed"]);
    exit;
}

// Ambil dan decode input JSON
$data = json_decode(file_get_contents("php://input"));
if (!$data || !isset($data->full_name) || !isset($data->password)) {
    echo json_encode(["status" => "error", "message" => "Invalid input"]);
    exit;
}

$full_name = $conn->real_escape_string($data->full_name);
$password = $data->password;

// Query user berdasarkan full_name
$query = "SELECT * FROM users WHERE full_name = '$full_name'";
$result = $conn->query($query);

if ($result && $result->num_rows === 1) {
    $user = $result->fetch_assoc();
    if (password_verify($password, $user['password'])) {
        echo json_encode([
            "status" => "success",
            "user" => [
                "id" => $user['id'],
                "full_name" => $user['full_name'],
                "email" => $user['email'],
                "phone" => $user['phone'],
                "profile_picture" => $user['profile_picture'],
                "created_at" => $user['created_at'],
            ]
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Invalid password"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "User not found"]);
}

$conn->close();
?>
