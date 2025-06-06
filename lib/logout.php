<?php
// 1. Mulai atau lanjutkan session
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// 2. Mengatur Header HTTP - sama seperti login.php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Access-control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Credentials: true");

// Handle preflight request (OPTIONS) dari browser
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// 3. Cek apakah user sudah login
if (!isset($_SESSION['logged_in']) || !isset($_SESSION['user_id'])) {
    http_response_code(401); // Unauthorized
    echo json_encode([
        "status" => "error", 
        "message" => "User is not logged in"
    ]);
    exit;
}

// 4. Hapus session
session_unset();
session_destroy();

// 5. Hapus cookie session
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 3600,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

// 6. Kirim respons logout berhasil
http_response_code(200); // OK
echo json_encode([
    "status" => "success",
    "message" => "Logged out successfully"
]);

exit;
?>