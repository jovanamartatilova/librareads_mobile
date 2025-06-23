import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class PdfViewerScreenReading extends StatefulWidget {
  final String pdfUrl;
  final String bookTitle;

  const PdfViewerScreenReading({Key? key, required this.pdfUrl, required this.bookTitle}) : super(key: key);

  @override
  State<PdfViewerScreenReading> createState() => _PdfViewerScreenReadingState();
}

class _PdfViewerScreenReadingState extends State<PdfViewerScreenReading> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String _errorMessage = '';
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
     debugPrint('Di PdfViewerScreenReading: Menerima pdfUrl: ${widget.pdfUrl}');
    _loadPdf();
  }
  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.pdfUrl.startsWith('assets/')) {
        final ByteData data = await rootBundle.load(widget.pdfUrl);
        setState(() {
          _pdfBytes = data.buffer.asUint8List();
          _isLoading = false;
        });
        debugPrint('Local PDF loaded: ${widget.pdfUrl}');
      } else {
        final response = await http.get(
          Uri.parse(widget.pdfUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.127 Safari/537.36',
            'Accept': 'application/pdf',
          },
        );

        if (response.statusCode == 200) {
          String? contentType = response.headers['content-type'];
          debugPrint('Content-Type from server: $contentType');

          if (contentType != null && contentType.contains('application/pdf')) {
            setState(() {
              _pdfBytes = response.bodyBytes;
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'The URL does not serve a direct PDF file. Content-Type: $contentType';
              _isLoading = false;
            });
            debugPrint('Error: Unexpected Content-Type for PDF. Expected application/pdf, got $contentType');
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to download PDF: Status ${response.statusCode}. Please try again.';
            _isLoading = false;
          });
          debugPrint('Failed to download PDF. Status: ${response.statusCode}, Body: ${response.body}');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF: Network error, invalid URL, or file not found. Message: $e';
        _isLoading = false;
      });
      debugPrint('Error loading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        title: Text(
          widget.bookTitle,
          style: const TextStyle(color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA28D4F)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadPdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA28D4F),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SfPdfViewer.memory(
                  _pdfBytes!,
                  controller: _pdfViewerController,
                  key: _pdfViewerKey,
                  onDocumentLoadFailed: (details) {
                    debugPrint('Failed to open loaded PDF bytes: ${details.description}');
                    setState(() {
                      _errorMessage = 'Failed to open the downloaded PDF document. ${details.description}';
                    });
                  },
                ),
    );
  }
}