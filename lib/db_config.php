<?php
$host = "localhost";
$user = "root";
$pass = ""; // ganti jika pakai password MySQL
$db = "librareads";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die(json_encode(["status" => false, "message" => "Database connection failed: " . $conn->connect_error]));
}
?>
