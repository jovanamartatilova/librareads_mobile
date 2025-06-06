<?php
ini_set('display_errors', 0); // Sembunyikan error ke client
error_reporting(0);

ini_set('log_errors', 1);
ini_set('error_log', 'error_log.txt');

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require __DIR__ . '/../vendor/autoload.php';


header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");

// Handle preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Ambil data dari request
$input = json_decode(file_get_contents('php://input'), true);
$email = $input['email'] ?? '';

if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => false, 'message' => 'Invalid email address']);
    exit;
}

// Koneksi database
$host = "localhost";
$user = "root";
$password = "";
$db = "librareads";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(['status' => false, 'message' => 'Database connection failed']);
    exit;
}

// Cek apakah email ada di tabel users
$stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows == 0) {
    echo json_encode(['status' => false, 'message' => 'Email not found']);
    exit;
}

$user = $result->fetch_assoc();
$user_id = $user['id'];

// Buat token dan waktu kadaluarsa
$token = bin2hex(random_bytes(16));
$expiry = date('Y-m-d H:i:s', strtotime('+1 hour'));

// Simpan ke tabel forgotpassword
$stmt = $conn->prepare("INSERT INTO forgotpassword (user_id, token, expires_at) VALUES (?, ?, ?)");
$stmt->bind_param("iss", $user_id, $token, $expiry);

if (!$stmt->execute()) {
    echo json_encode(['status' => false, 'message' => 'Failed to save reset token']);
    exit;
}

// Kirim email pakai PHPMailer
$mail = new PHPMailer(true);

try {
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'jovanamartatilova@gmail.com';
    $mail->Password = 'huut glik emlx uixp'; // bukan password biasa!
    $mail->SMTPSecure = 'tls';
    $mail->Port = 587;

    $mail->setFrom('no-reply@librareads.com', 'LibraReads');
    $mail->addAddress($email);

    $resetLink = "http://192.168.100.22:8080/fotgotpassword.php?token=$token";

    $mail->isHTML(true);
    $mail->Subject = 'Password Reset Request';
    $mail->SMTPDebug = 2; // Enable detailed debug output
    $mail->Debugoutput = 'error_log'; // Send debug output to the error log file
    $mail->Body = "
        <p>Hello,</p>
        <p>Kami menerima permintaan reset password. Klik link di bawah ini untuk mengatur ulang password Anda:</p>
        <p><a href='$resetLink'>$resetLink</a></p>
        <p>Jika Anda tidak meminta reset password, abaikan email ini.</p>
    ";

    $mail->send();
    echo json_encode(['status' => true, 'message' => 'Reset link has been sent to your email']);
} catch (Exception $e) {
    echo json_encode(['status' => false, 'message' => 'Mailer Error: ' . $mail->ErrorInfo]);
}

$conn->close();
