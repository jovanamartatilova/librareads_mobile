<?php
require_once('pdf2text.php');  // PDF extraction

// Fungsi untuk ekstraksi teks dan simpan ke database
function extractAndSaveText($pdfFilePath, $bookTitle) {
    $text = pdf2text($pdfFilePath);
    
    // Simpan teks hasil ekstraksi ke database
    $conn = new mysqli('localhost', 'root', '', 'librareads');
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }
    
    $query = "UPDATE books SET text_content = ? WHERE title = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param('ss', $text, $bookTitle);
    $stmt->execute();
    $stmt->close();
    $conn->close();
    
    echo "Text extraction and saving completed!";
}

// Call the function for each PDF file (this can be run periodically)
extractAndSaveText('path_to_pdf_file.pdf', 'Effective Modern C++');
?>
