<?php
// Aktifkan error reporting untuk debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Tambahkan CORS headers di bagian paling atas
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Allow-Credentials: true');
header('Content-Type: application/json; charset=utf-8');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Pastikan direktori upload exists
$target_directory = 'uploads/profile_pictures/';
if (!file_exists($target_directory)) {
    if (!mkdir($target_directory, 0755, true)) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to create upload directory']);
        exit();
    }
}

session_start();
include 'db_config.php';

// Log untuk debugging
error_log("POST data: " . print_r($_POST, true));
error_log("FILES data: " . print_r($_FILES, true));

try {
    // Validasi user_id dari POST request
    $user_id = $_POST['user_id'] ?? null;
    if (!$user_id || !is_numeric($user_id)) {
        echo json_encode(['status' => 'error', 'message' => 'Valid User ID required']);
        exit();
    }

    // Validasi user_id exists di database
    $sql_validate = "SELECT id FROM users WHERE id = ?";
    $stmt_validate = $conn->prepare($sql_validate);
    $stmt_validate->bind_param("i", $user_id);
    $stmt_validate->execute();
    $result_validate = $stmt_validate->get_result();

    if ($result_validate->num_rows == 0) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid user ID']);
        exit();
    }

    $new_username = $_POST['username'] ?? '';

    // Fungsi untuk validasi file gambar
    function validateImageFile($file) {
        $allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
        $allowed_mime = ['image/jpeg', 'image/png', 'image/gif'];
        $max_size = 10 * 1024 * 1024; // 5MB
        
        // Cek MIME type
        if (!in_array($file['type'], $allowed_mime)) {
            return ['valid' => false, 'message' => 'File type not allowed. Only JPEG, PNG, and GIF are allowed.'];
        }
        
        // Cek ukuran file
        if ($file['size'] > $max_size) {
            return ['valid' => false, 'message' => 'File size too large. Maximum size is 5MB.'];
        }
        
        // Validasi tambahan dengan getimagesize
        $image_info = getimagesize($file['tmp_name']);
        if ($image_info === false) {
            return ['valid' => false, 'message' => 'Invalid image file.'];
        }
        
        return ['valid' => true];
    }

    // Fungsi untuk generate nama file unik
    function generateUniqueFileName($original_name, $user_id) {
        $extension = strtolower(pathinfo($original_name, PATHINFO_EXTENSION));
        $timestamp = time();
        $random = mt_rand(1000, 9999);
        $filename = 'profile_' . $user_id . '_' . $timestamp . '_' . $random . '.' . $extension;
        
        error_log("Generated filename: " . $filename);
        return $filename;
    }

    // Validasi upload error jika ada file
    if (isset($_FILES['profile_picture'])) {
        $upload_error = $_FILES['profile_picture']['error'];
        
        switch ($upload_error) {
            case UPLOAD_ERR_INI_SIZE:
            case UPLOAD_ERR_FORM_SIZE:
                echo json_encode(['status' => 'error', 'message' => 'File size too large']);
                exit();
            case UPLOAD_ERR_PARTIAL:
                echo json_encode(['status' => 'error', 'message' => 'File upload incomplete']);
                exit();
            case UPLOAD_ERR_NO_TMP_DIR:
                echo json_encode(['status' => 'error', 'message' => 'Temporary directory missing']);
                exit();
            case UPLOAD_ERR_CANT_WRITE:
                echo json_encode(['status' => 'error', 'message' => 'Cannot write file to disk']);
                exit();
            case UPLOAD_ERR_NO_FILE:
                // File tidak ada, lanjutkan untuk update username saja
                break;
            case UPLOAD_ERR_OK:
                // File OK, lanjutkan proses
                break;
            default:
                echo json_encode(['status' => 'error', 'message' => 'Unknown upload error: ' . $upload_error]);
                exit();
        }
    }

    // Memeriksa apakah foto profil baru diupload
    if (isset($_FILES['profile_picture']) && $_FILES['profile_picture']['error'] == UPLOAD_ERR_OK) {
        
        // Validasi file gambar
        $validation = validateImageFile($_FILES['profile_picture']);
        if (!$validation['valid']) {
            echo json_encode(['status' => 'error', 'message' => $validation['message']]);
            exit();
        }
        
        // Generate nama file unik
        $original_filename = $_FILES['profile_picture']['name'];
        $new_filename = generateUniqueFileName($original_filename, $user_id);
        $target_file = $target_directory . $new_filename;
        
        error_log("Original filename: " . $original_filename);
        error_log("New filename: " . $new_filename);
        error_log("Target file: " . $target_file);
        
        // Pastikan file berhasil diupload
        if (move_uploaded_file($_FILES['profile_picture']['tmp_name'], $target_file)) {
            
            // Ambil foto profil lama untuk dihapus
            $sql_old = "SELECT profile_picture FROM users WHERE id = ?";
            $stmt_old = $conn->prepare($sql_old);
            $stmt_old->bind_param("i", $user_id);
            $stmt_old->execute();
            $result_old = $stmt_old->get_result();
            $old_data = $result_old->fetch_assoc();
            
            // Hapus foto lama jika ada dan bukan default
            if ($old_data && $old_data['profile_picture'] && 
                $old_data['profile_picture'] !== 'default.jpg' && 
                file_exists($target_directory . $old_data['profile_picture'])) {
                unlink($target_directory . $old_data['profile_picture']);
                error_log("Deleted old profile picture: " . $old_data['profile_picture']);
            }
            
            // Jika ada username baru, update keduanya
            if (!empty($new_username)) {
                // Cek apakah username sudah digunakan user lain
                $sql_check = "SELECT id FROM users WHERE username = ? AND id != ?";
                $stmt_check = $conn->prepare($sql_check);
                $stmt_check->bind_param("si", $new_username, $user_id);
                $stmt_check->execute();
                $result_check = $stmt_check->get_result();
                
                if ($result_check->num_rows > 0) {
                    // Hapus file yang baru diupload karena username sudah ada
                    unlink($target_file);
                    echo json_encode(['status' => 'error', 'message' => 'Username already exists']);
                    exit();
                }
                
                $sql = "UPDATE users SET profile_picture = ?, username = ? WHERE id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("ssi", $new_filename, $new_username, $user_id);
            } else {
                // Hanya update gambar
                $sql = "UPDATE users SET profile_picture = ? WHERE id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("si", $new_filename, $user_id);
            }
            
            if ($stmt->execute()) {
                // Return URL lengkap untuk gambar
                $protocol = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on') ? 'https' : 'http';
                $host = $_SERVER['HTTP_HOST'];
                $script_dir = str_replace('/lib', '', dirname($_SERVER['SCRIPT_NAME']));
                
                // Pastikan tidak ada double slash
                $base_url = $protocol . '://' . $host . rtrim($script_dir, '/') . '/';
                $profile_picture_url = $base_url . $target_directory . $new_filename;
                
                 error_log("=== URL GENERATION DEBUG ===");
                error_log("Protocol: " . $protocol);
                error_log("Host: " . $host);
                error_log("Original script_dir: " . dirname($_SERVER['SCRIPT_NAME']));
                error_log("Fixed script_dir: " . $script_dir);
                error_log("Base URL: " . $base_url);
                error_log("Target directory: " . $target_directory);
                error_log("New filename: " . $new_filename);
                error_log("Final URL: " . $profile_picture_url);
                error_log("=== END DEBUG ===");

                if (file_exists($target_file)) {
                    error_log("✅ File confirmed exists at: " . $target_file);
                } else {
                    error_log("❌ File NOT found at: " . $target_file);
                }
                
                echo json_encode([
                    'status' => 'success', 
                    'message' => 'Profile updated successfully',
                    'profile_picture_url' => $profile_picture_url,
                    'username' => $new_username ?: null,
                    'filename' => $new_filename,
                    'debug_info' => [
                        'target_file' => $target_file,
                        'file_exists' => file_exists($target_file),
                        'base_url' => $base_url,
                        'target_directory' => $target_directory
                    ]
                ]);
            } else {
                // Hapus file jika gagal update database
                unlink($target_file);
                echo json_encode(['status' => 'error', 'message' => 'Failed to update profile in database: ' . $conn->error]);
            }
            
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to upload profile picture. Check directory permissions.']);
            exit();
        }
        
    } else if (!empty($new_username)) {
        // Jika tidak ada gambar baru, hanya update username
        
        // Cek apakah username sudah digunakan user lain
        $sql_check = "SELECT id FROM users WHERE username = ? AND id != ?";
        $stmt_check = $conn->prepare($sql_check);
        $stmt_check->bind_param("si", $new_username, $user_id);
        $stmt_check->execute();
        $result_check = $stmt_check->get_result();
        
        if ($result_check->num_rows > 0) {
            echo json_encode(['status' => 'error', 'message' => 'Username already exists']);
            exit();
        }
        
        $sql = "UPDATE users SET username = ? WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("si", $new_username, $user_id);
        
        if ($stmt->execute()) {
            echo json_encode([
                'status' => 'success', 
                'message' => 'Username updated successfully',
                'username' => $new_username
            ]);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to update username: ' . $conn->error]);
        }
        
    } else {
        echo json_encode(['status' => 'error', 'message' => 'No data to update']);
    }
    
} catch (Exception $e) {
    error_log("Update profile error: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    echo json_encode([
        'status' => 'error', 
        'message' => 'Server error occurred: ' . $e->getMessage()
    ]);
} catch (Error $e) {
    error_log("Fatal error: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    echo json_encode([
        'status' => 'error', 
        'message' => 'Fatal server error: ' . $e->getMessage()
    ]);
}

if (isset($conn)) {
    $conn->close();
}
?>