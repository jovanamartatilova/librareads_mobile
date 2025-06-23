import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfPath; // Expects a local asset path (e.g., 'assets/pdfs/mybook.pdf')
  final String bookTitle;

  const PdfViewerScreen({
    Key? key,
    required this.pdfPath,
    required this.bookTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121921),
        title: Text(
          bookTitle,
          style: const TextStyle(
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SfPdfViewer.asset(pdfPath), // Uses SfPdfViewer.asset
    );
  }
}