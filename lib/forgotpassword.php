<?php
ini_set('display_errors', 0);
error_reporting(0);

ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/error_log.txt');
error_log("forgotpassword.php script started.");

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\SMTP;

require __DIR__ . '/../vendor/autoload.php';

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);
$email = $input['email'] ?? '';

if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_log("Invalid email format received: " . ($email ?? 'NULL'));
    echo json_encode(['status' => false, 'message' => 'Invalid email address.']);
    exit;
}

$host = "localhost";
$user = "root";
$password = "";
$db = "librareads";
$pdo = null;

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    error_log("Database connected successfully.");
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        error_log("Email not found in users table: " . $email);
        echo json_encode(['status' => false, 'message' => 'If your email is registered, a reset code will be sent.']);
        exit;
    }

    $user_id = $user['id'];
    error_log("User ID found: " . $user_id . " for email: " . $email);

    $stmt_delete = $pdo->prepare("DELETE FROM forgotpassword WHERE user_id = ?");
    $stmt_delete->execute([$user_id]);
    error_log("Old tokens deleted for user ID: " . $user_id . ". Rows affected: " . $stmt_delete->rowCount());

    $token = random_int(100000, 999999);
    $expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));
    error_log("Generated 6-digit token: " . $token . ", expires at: " . $expiry);

    $stmt_insert = $pdo->prepare("INSERT INTO forgotpassword (user_id, token, expires_at) VALUES (?, ?, ?)");

    if (!$stmt_insert->execute([$user_id, $token, $expiry])) {
        error_log("Failed to save reset token to database: " . implode(" | ", $stmt_insert->errorInfo()));
        echo json_encode(['status' => false, 'message' => 'Failed to save reset token to the database. Please try again later.']);
        exit;
    }
    error_log("Token SUCCESSFULLY saved to database. UserID: " . $user_id . ", Token: " . $token . ", Expires: " . $expiry);

    $mail = new PHPMailer(true);

    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'jovanamartatilova@gmail.com';
    $mail->Password = 'yiqh rwhb xeqr jdow';
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = 587;
    $mail->setFrom('no-reply@librareads.com', 'LibraReads');
    $mail->addAddress($email);
    $mail->isHTML(true);
    $mail->Subject = 'LibraReads Password Reset Request';

    $emailBody = "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>LibraReads Password Reset</title>
        <style>
            body {
                font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
                margin: 0;
                padding: 0;
                background-color: #f4f4f4;
                color: #000000; /* Changed to black */
            }
            .container {
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 8px;
                overflow: hidden;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            }
            .header {
                background-color: #A28D4F; /* Gold/Brown color for Header */
                color: #ffffff;
                padding: 20px 30px;
                text-align: center;
                font-size: 24px;
                font-weight: bold;
            }
            .content {
                padding: 30px;
                line-height: 1.6;
                text-align: center;
                color: #000000; /* Changed to black */
            }
            .token-box {
                background-color: #EFEFEF; /* Light grey */
                border: 1px dashed #CCC;
                padding: 15px 25px;
                margin: 20px auto;
                font-size: 28px;
                font-weight: bold;
                color: #000000; /* Changed to black */
                border-radius: 5px;
                max-width: 250px;
                text-align: center;
                letter-spacing: 2px;
            }
            .footer {
                background-color: #f0f0f0;
                color: #777;
                padding: 20px 30px;
                font-size: 12px;
                text-align: center;
                border-top: 1px solid #eee;
            }
            .button {
                display: inline-block;
                background-color: #A28D4F;
                color: #ffffff;
                padding: 10px 20px;
                border-radius: 5px;
                text-decoration: none;
                margin-top: 20px;
            }
            .note {
                font-size: 13px;
                color: #000000; /* Changed to black */
                margin-top: 20px;
            }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                LibraReads
            </div>
            <div class='content'>
                <p>Hello,</p>
                <p>We received a request to reset the password for your account on LibraReads.</p>
                <p>Please use the 6-digit verification code below to proceed with your password reset:</p>
                <div class='token-box'>
                    <strong>" . htmlspecialchars($token) . "</strong>
                </div>
                <p class='note'>
                    This code will expire in 10 minutes.
                </p>
                <p>If you did not request a password reset, please ignore this email.</p>
                <p>Thank you for using LibraReads.</p>
            </div>
            <div class='footer'>
                &copy; " . date("Y") . " LibraReads. All Rights Reserved.<br>
                This email was sent automatically, please do not reply.
            </div>
        </div>
    </body>
    </html>
    ";

    $mail->Body = $emailBody;
    $mail->AltBody = "Hello,\n\nWe received a request to reset the password for your account on LibraReads.\n\nPlease use the 6-digit verification code below to proceed with your password reset:\n\nYour Verification Code: " . $token . "\n\nThis code will expire in 10 minutes.\n\nIf you did not request a password reset, please ignore this email.\n\nThank you for using LibraReads,\nLibraReads Team";

    $mail->send();
    error_log("Password reset email successfully sent to: " . $email);
    echo json_encode(['status' => true, 'message' => 'A password reset code has been sent to your email!']);

} catch (PDOException $e) {
    error_log("Database Error (PDOException) in forgotpassword.php: " . $e->getMessage());
    echo json_encode(['status' => false, 'message' => 'A database error occurred while processing the request.']);
} catch (Exception $e) {
    error_log("PHPMailer/General Error in forgotpassword.php: " . $e->getMessage() . " | Info: " . ($mail->ErrorInfo ?? 'N/A'));
    echo json_encode(['status' => false, 'message' => 'Failed to send verification code. Please try again later.']);
} finally {
    if ($pdo) {
        $pdo = null;
    }
}
?>