<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

$host = "localhost";
$user = "root";
$pass = "";
$db = "librareads";

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed: " . $conn->connect_error
    ]);
    exit;
}

$conn->set_charset("utf8");

try {
    $book_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

    $query = "SELECT
                b.id,
                b.title, 
                b.author, 
                b.category, 
                b.cover_image_url, 
                b.total_chunks, 
                b.created_at,
                b.pdf_file_url,
                COUNT(bc.id) as actual_chunks
              FROM books b 
              LEFT JOIN book_contents bc ON b.id = bc.book_id ";

    if ($book_id > 0) {
        $query .= " WHERE b.id = ? ";
    }

    $query .= " GROUP BY b.id, b.title, b.author, b.category, b.cover_image_url, b.total_chunks, b.created_at, b.pdf_file_url 
                 ORDER BY b.created_at DESC";

    $stmt = $conn->prepare($query);

    if ($book_id > 0) {
        $stmt->bind_param("i", $book_id);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    $books = [];

    while ($row = $result->fetch_assoc()) {
        $book = [
            "id" => (int)$row["id"],
            "title" => $row["title"] ?? "Unknown Title",
            "author" => $row["author"] ?? "Unknown Author",
            "category" => $row["category"] ?? "General",
            "cover_image_url" => $row["cover_image_url"],
            "total_chunks" => (int)($row["total_chunks"] ?? 0),
            "actual_chunks" => (int)($row["actual_chunks"] ?? 0),
            "created_at" => $row["created_at"],
            "is_complete" => ((int)$row["total_chunks"]) === ((int)$row["actual_chunks"]) && $row["total_chunks"] > 0,
            "pdf_file_url" => $row["pdf_file_url"] ?? null
        ];
        $books[] = $book;
    }

    if (empty($books)) {
        echo json_encode([
            "status" => "success", 
            "message" => "No books found",
            "books" => [],
            "total_count" => 0
        ]);
    } else {
        echo json_encode([
            "status" => "success", 
            "books" => $books,
            "total_count" => count($books),
            "message" => "Books retrieved successfully"
        ]);
    }

    $stmt->close();

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