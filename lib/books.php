<?php
// Mengatur header untuk JSON
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');


// Koneksi ke database MySQL
$host = "localhost";
$user = "root";   // Ganti dengan username MySQL kamu
$pass = "";       // Ganti dengan password MySQL kamu
$db = "librareads"; // Ganti dengan nama database kamu

$conn = new mysqli($host, $user, $pass, $db);

// Cek koneksi
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => "Database connection failed: " . $conn->connect_error
    ]);
    exit;
}

// Set charset untuk koneksi
$conn->set_charset("utf8");

try {
    // Query untuk mengambil semua buku dengan informasi lengkap
    // Menambahkan `b.pdf_file_url` ke SELECT dan GROUP BY
    $query = "SELECT 
                b.id, 
                b.title, 
                b.author, 
                b.category, 
                b.cover_image_url, 
                b.total_chunks, 
                b.created_at,
                b.pdf_file_url, -- <--- KOLOM INI HARUS ADA DI DATABASE DAN DIAMBIL
                COUNT(bc.id) as actual_chunks
              FROM books b 
              LEFT JOIN book_contents bc ON b.id = bc.book_id 
              GROUP BY b.id, b.title, b.author, b.category, b.cover_image_url, b.total_chunks, b.created_at, b.pdf_file_url 
              ORDER BY b.created_at DESC";
              
    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }

    // Menyusun array untuk menyimpan data buku
    $books = [];

    while ($row = $result->fetch_assoc()) {
        // Menyusun data buku yang akan dikirim ke aplikasi
        $book = [
            "id" => (int)$row["id"],
            "title" => $row["title"] ?? "Unknown Title",
            "author" => $row["author"] ?? "Unknown Author",
            "category" => $row["category"] ?? "General",
            // Membangun URL lengkap untuk cover image dari path relatif
            "cover_image_url" => $row["cover_image_url"],
            "total_chunks" => (int)($row["total_chunks"] ?? 0),
            "actual_chunks" => (int)($row["actual_chunks"] ?? 0), // Jumlah chunk yang sebenarnya ada
            "created_at" => $row["created_at"],
            "is_complete" => ((int)$row["total_chunks"]) === ((int)$row["actual_chunks"]) && $row["total_chunks"] > 0,
            "pdf_file_url" => $row["pdf_file_url"] ?? null // <--- KOLOM INI HARUS ADA DAN DIAMBIL
        ];
        $books[] = $book;
    }

    // Cek apakah data ada
    if (empty($books)) {
        echo json_encode([
            "status" => "success", 
            "message" => "No books found",
            "books" => [],
            "total_count" => 0
        ]);
    } else {
        // Mengembalikan data dalam format JSON
        echo json_encode([
            "status" => "success", 
            "books" => $books,
            "total_count" => count($books),
            "message" => "Books retrieved successfully"
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => "Server error: " . $e->getMessage()
    ]);
} finally {
    $conn->close();
}
?>
