import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppConfig {
  static const String baseUrl = 'http://192.168.100.22:8080/librareadsmob';
  static const String bookContentEndpoint = '$baseUrl/lib/book_contents.php';
}

class BookReadingScreen extends StatefulWidget {
  final String bookTitle;
  final String bookAuthor;
  final String bookImage;
  final String bookFileUrl;
  final int bookId;

  const BookReadingScreen({
    super.key,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookImage,
    required this.bookFileUrl,
    this.bookId = 0,
  });

  @override
  State<BookReadingScreen> createState() => _BookReadingScreenState();
}

class _BookReadingScreenState extends State<BookReadingScreen> {
  bool _hasError = false;
  String? _bookDescription;

  @override
  void initState() {
    super.initState();
    _fetchBookDescription();
  }

  Future<void> _fetchBookDescription() async {
    if (widget.bookId <= 0) {
      debugPrint('Book ID is not provided or invalid. Cannot fetch description.');
      setState(() {
        _bookDescription = 'No description available.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.bookContentEndpoint}?book_id=${widget.bookId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] is List && data['data'].isNotEmpty) {
          setState(() {
            _bookDescription = data['data'][0]['content']?.toString() ?? 'No description available.';
          });
        } else {
          setState(() {
            _bookDescription = data['message'] ?? 'Failed to load description.';
          });
          debugPrint('API Error: ${data['message']}');
        }
      } else {
        setState(() {
          _bookDescription = 'Server error: ${response.statusCode}. Failed to load description.';
        });
        debugPrint('Server Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _bookDescription = 'Network error fetching description.';
      });
      debugPrint('Error fetching book description: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchPdfUrl() async {
    if (widget.bookFileUrl.isEmpty) {
      setState(() {
        _hasError = true;
      });
      _showErrorSnackBar('PDF URL is not available.');
      return;
    }

    final Uri url = Uri.parse(widget.bookFileUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      setState(() {
        _hasError = true;
      });
      _showErrorSnackBar('Could not launch ${widget.bookFileUrl}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        title: Text(
          widget.bookTitle,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book Cover Image
              Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect( 
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    widget.bookImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading book image: $error');
                      return Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.book, size: 100, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Book Title
              Text(
                widget.bookTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Book Author
              Text(
                widget.bookAuthor,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              // Book Description (dari book_contents)
              if (_bookDescription != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _bookDescription!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    // maxLines dan overflow dihapus agar teks tidak terpotong
                  ),
                ),
              const SizedBox(height: 24),
              // Open Book Button
              ElevatedButton.icon(
                onPressed: _hasError ? null : _launchPdfUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA28D4F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Open Book'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}