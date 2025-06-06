<?php
// Mengatur header untuk JSON
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Koneksi ke database MySQL
$host = "localhost";
$user = "root";
$pass = "";
$db = "librareads";

$conn = new mysqli($host, $user, $pass, $db);

// Cek koneksi
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => "Database connection failed"
    ]);
    exit;
}

$conn->set_charset("utf8");

try {
    // Ambil parameter dari request
    $book_id = isset($_GET['book_id']) ? (int)$_GET['book_id'] : 0;
    $chunk_number = isset($_GET['chunk_number']) ? (int)$_GET['chunk_number'] : 1;

    if ($book_id <= 0) {
        throw new Exception("Invalid book ID");
    }

    // Jika chunk_number tidak ditentukan, ambil semua chunk
    if (isset($_GET['chunk_number'])) {
        // Ambil chunk tertentu
        $query = "SELECT bc.*, b.title, b.author 
                    FROM book_contents bc 
                    JOIN books b ON bc.book_id = b.id 
                    WHERE bc.book_id = ? AND bc.chunk_number = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $book_id, $chunk_number);
    } else {
        // Ambil semua chunk untuk buku tertentu
        $query = "SELECT bc.*, b.title, b.author 
                    FROM book_contents bc 
                    JOIN books b ON bc.book_id = b.id 
                    WHERE bc.book_id = ? 
                    ORDER BY bc.chunk_number ASC";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $book_id);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $contents = [];
    while ($row = $result->fetch_assoc()) {
        $content = [
            "id" => (int)$row["id"],
            "book_id" => (int)$row["book_id"],
            "chunk_number" => (int)$row["chunk_number"],
            "content" => $row["content"],
            "book_title" => $row["title"],
            "book_author" => $row["author"]
        ];
        $contents[] = $content;
    }

    if (empty($contents)) {
        echo json_encode([
            "status" => "error", 
            "message" => "No content found for this book/chunk"
        ]);
    } else {
        echo json_encode([
            "status" => "success", 
            "data" => isset($_GET['chunk_number']) ? $contents[0] : $contents,
            "total_chunks" => count($contents)
        ]);
    }

    $stmt->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "status" => "error", 
        "message" => $e->getMessage()
    ]);
} finally {
    $conn->close();
}
?>
