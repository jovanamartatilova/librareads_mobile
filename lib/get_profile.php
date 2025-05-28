<?php
// Mulai session
// Ini harus dipanggil sebelum output apapun ke browser
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Menampilkan semua error sebagai JSON untuk debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Mengatur header untuk respons JSON dan CORS
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *"); // Sesuaikan untuk environment production. Untuk session, ini mungkin perlu lebih ketat dan Allow-Credentials.
header("Access-Control-Allow-Credentials: true"); // Penting untuk session/cookies lintas domain
header("Access-Control-Allow-Methods: GET, POST, OPTIONS"); // Izinkan GET, POST (jika diperlukan), dan OPTIONS
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-Csrf-Token"); // Tambahkan header yang mungkin dibutuhkan

// Handle preflight request untuk CORS
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Detail koneksi database
$host = "localhost";
$user = "root";
$password_db = ""; // Ganti jika database Anda menggunakan password
$db_name = "librareads";

// Membuat koneksi ke database
$conn = new mysqli($host, $user, $password_db, $db_name);

// Periksa koneksi
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Connection failed: " . $conn->connect_error]);
    exit;
}

// Periksa apakah pengguna sudah login dengan melihat session
if (!isset($_SESSION['logged_in']) || $_SESSION['logged_in'] !== true || !isset($_SESSION['user_id'])) {
    http_response_code(401); // Unauthorized
    echo json_encode(["status" => "error", "message" => "Unauthorized. Please login first."]);
    $conn->close();
    exit;
}

// Ambil user_id dari session
$userId = $_SESSION['user_id'];

// Validasi user_id dari session (seharusnya sudah integer jika diatur dengan benar di login.php)
if (!is_numeric($userId)) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["status" => "error", "message" => "Invalid user_id in session."]);
    $conn->close();
    exit;
}

// Persiapkan statement SQL untuk mengambil profile_picture
// Menggunakan prepared statement untuk mencegah SQL injection
$stmt = $conn->prepare("SELECT profile_picture FROM users WHERE id = ?");
if (!$stmt) {
    // Jika prepare statement gagal
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Prepare statement failed: " . $conn->error]);
    $conn->close();
    exit;
}

// Bind parameter user_id ke statement
$stmt->bind_param("i", $userId); // "i" menandakan tipe integer

// Eksekusi statement
if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Execute statement failed: " . $stmt->error]);
    $stmt->close();
    $conn->close();
    exit;
}

// Dapatkan hasil query
$result = $stmt->get_result();

if ($result && $result->num_rows === 1) {
    // User ditemukan
    $user_data = $result->fetch_assoc();
    $profilePictureFilename = $user_data['profile_picture'];

    $baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http") . "://" . $_SERVER['HTTP_HOST'];
    // Tentukan path dasar ke folder uploads. Sesuaikan jika struktur folder Anda berbeda.
    // Contoh: jika skrip PHP ada di /api/get_profile.php dan uploads di /uploads/
    // maka $baseUploadPath bisa jadi $baseUrl . "/uploads/";
    // Atau jika uploads sejajar dengan folder api: $baseUrl . "/../uploads/"; (perlu penanganan path yang lebih baik)
    // Untuk kesederhanaan, kita asumsikan uploads ada di root atau path yang bisa diakses langsung
    $baseUploadPath = $baseUrl . "/uploads/"; // Pastikan folder 'uploads' dapat diakses via web

    if ($profilePictureFilename !== null && !empty(trim($profilePictureFilename))) {
        // Jika ada nama file foto profil, bentuk URL lengkapnya
        $profilePictureUrl = $baseUploadPath . $profilePictureFilename;
        echo json_encode([
            "status" => "success",
            "user_id" => $userId,
            "profile_picture_url" => $profilePictureUrl
        ]);
    } else {
        // User ditemukan tapi tidak memiliki foto profil
        echo json_encode([
            "status" => "success",
            "user_id" => $userId,
            "profile_picture_url" => null, // Atau bisa juga URL ke gambar default
            "message" => "User does not have a profile picture set."
        ]);
    }
} else if ($result->num_rows === 0) {
    // User tidak ditemukan (seharusnya tidak terjadi jika user_id dari session valid)
    http_response_code(404);
    echo json_encode(["status" => "error", "message" => "User not found in database, but was in session. Session data might be stale."]);
} else {
    // Terjadi kesalahan lain saat mengambil data
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "An error occurred while fetching profile data."]);
}

// Tutup statement dan koneksi
$stmt->close();
$conn->close();
?>
