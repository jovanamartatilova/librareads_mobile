import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'centered_message_overlay.dart';
import 'pdf_viewer_reading.dart';
import 'books.dart';
import 'main.dart';
class BookReadingScreen extends StatefulWidget {
  final String bookTitle;
  final String bookAuthor;
  final String bookImage;
  final String bookFileUrl;
  final String bookId;

  const BookReadingScreen({
    super.key,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookImage,
    required this.bookFileUrl,
    required this.bookId,
  });

  @override
  State<BookReadingScreen> createState() => _BookReadingScreenState();
}

class _BookReadingScreenState extends State<BookReadingScreen> {
  String? _bookDescription;
  bool _isBookSaved = false;

  @override
  void initState() {
    super.initState();
    _bookDescription = _findBookDescriptionLocally(widget.bookId);
    _checkIfBookSaved();
  }

  String _findBookDescriptionLocally(String bookId) {
    try {
      final Book foundBook = allBooks.firstWhere(
        (book) => book.id == bookId,
        orElse: () {
          debugPrint('Book with ID $bookId not found in local allBooks. Using default description.');
          return Book(
            id: bookId,
            title: widget.bookTitle,
            author: widget.bookAuthor,
            imagePath: widget.bookImage,
            description: 'Description not available locally.',
            category: '',
            pageCount: 0,
            pdfAssetPath: widget.bookFileUrl,
          );
        },
      );
      return foundBook.description;
    } catch (e) {
      debugPrint('Error finding local book description for ID $bookId: $e');
      return 'Description not available locally due to an error.';
    }
  }

  Future<void> _checkIfBookSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedBookIds = prefs.getStringList('savedBookIds') ?? [];
      setState(() {
        _isBookSaved = savedBookIds.contains(widget.bookId);
      });
    } catch (e) {
      debugPrint('Error checking saved book status: $e');
    }
  }

  Future<void> _toggleSaveBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedBookIds = prefs.getStringList('savedBookIds') ?? [];

      if (_isBookSaved) {
        savedBookIds.remove(widget.bookId);
        showCenteredMessageOverlay(context, 'Book removed from bookshelf!', false);
      } else {
        savedBookIds.add(widget.bookId);
        showCenteredMessageOverlay(context, 'Book added to bookshelf!', true);
      }
      await prefs.setStringList('savedBookIds', savedBookIds);
      setState(() {
        _isBookSaved = !_isBookSaved;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to save/remove book: $e');
      debugPrint('Error toggling save book: $e');
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

  void _openPdfInApp() {
    debugPrint('Attempting to open PDF from: ${widget.bookFileUrl}');
    debugPrint('From BookReadingScreen: Sending widget.bookFileUrl: ${widget.bookFileUrl} to PdfViewerScreenReading');

    if (widget.bookFileUrl.isEmpty) {
      _showErrorSnackBar('PDF URL is not available.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreenReading(
          pdfUrl: widget.bookFileUrl,
          bookTitle: widget.bookTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLocalImage = widget.bookImage.startsWith('assets/');

    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        title: Text(
          widget.bookTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookSaved ? const Color(0xFFA28D4F) : Colors.white,
            ),
            onPressed: _toggleSaveBook,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: 'book_cover_${widget.bookId}',
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A2E40),
                        const Color(0xFF1A1D29).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isLocalImage
                        ? Image.asset(
                            widget.bookImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Error loading local asset image: $error');
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.book, size: 100, color: Colors.grey),
                              );
                            },
                          )
                        : CachedNetworkImage(
                            imageUrl: widget.bookImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFFA28D4F)),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint('Error loading network image: $error');
                              return Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.book, size: 100, color: Colors.grey),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                widget.bookTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              const SizedBox(height: 10),

              Text(
                widget.bookAuthor,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D29),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 0.5),
                ),
                child: Text(
                  _bookDescription ?? 'Description not available.',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openPdfInApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA28D4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 24),
                  label: const Text(
                    'Read Book Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}