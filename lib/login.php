<?php
// 1. Mulai atau lanjutkan session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Menampilkan semua error sebagai JSON (hanya untuk development)
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 2. Mengatur Header HTTP
header("Content-Type: application/json");
// Izinkan permintaan dari origin manapun. Untuk production, ganti '*' dengan domain aplikasi Anda.
header("Access-Control-Allow-Origin: *"); 
// Izinkan header yang dibutuhkan untuk CORS dan tipe konten.
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
// Izinkan metode request yang digunakan.
header("Access-control-Allow-Methods: POST, OPTIONS");
// PENTING: Izinkan pengiriman credentials (seperti cookies untuk session).
header("Access-Control-Allow-Credentials: true");

// Handle preflight request (OPTIONS) dari browser
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 3. Koneksi ke Database
$host = "localhost";
$user = "root";
$password = "";
$db = "librareads";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]);
    exit;
}

// 4. Ambil dan Decode Input JSON
$data = json_decode(file_get_contents("php://input"));

// Validasi input
if (!$data || !isset($data->username) || !isset($data->password)) {
    http_response_code(400); // Bad Request
    echo json_encode(["status" => "error", "message" => "Invalid input. 'username' and 'password' are required."]);
    exit;
}

$username_input = $data->username;
$password_input = $data->password;

// 5. Query User Menggunakan Prepared Statements (Aman dari SQL Injection)
$query = "SELECT id, username, email, profile_picture, password, created_at FROM users WHERE username = ?";
$stmt = $conn->prepare($query);

if (!$stmt) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Prepare statement failed: " . $conn->error]);
    exit;
}

$stmt->bind_param("s", $username_input);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();

    // 6. Verifikasi Password
    if (password_verify($password_input, $user['password'])) {
        // Password cocok, login berhasil!

        // 7. Buat Ulang Session ID untuk Keamanan (Mencegah Session Fixation)
        session_regenerate_id(true);

        // 8. Simpan Data Pengguna ke dalam Session
        $_SESSION['logged_in'] = true;
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['email'] = $user['email'];

        // Hapus password dari array sebelum mengirim ke klien
        unset($user['password']);

        // 9. Kirim Respons Sukses ke Klien
        http_response_code(200); // OK
        echo json_encode([
            "status" => "success",
            "message" => "Login successful",
            "user" => $user // Kirim data user (tanpa password)
        ]);

    } else {
        // Password salah
        http_response_code(401); // Unauthorized
        echo json_encode(["status" => "error", "message" => "Invalid full name or password."]);
    }
} else {
    // User tidak ditemukan
    http_response_code(401); // Unauthorized
    echo json_encode(["status" => "error", "message" => "Invalid full name or password."]);
}

$stmt->close();
$conn->close();
?>