<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-control-Allow-Methods: POST, GET, PUT, DELETE, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

http_response_code(200);
echo json_encode([
    "status" => "success",
    "message" => "Logout successful. Please ensure client-side token is removed."
]);

exit;
?>