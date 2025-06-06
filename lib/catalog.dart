import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mybooks.dart';
import 'profile.dart';
import 'reading.dart';
import 'main.dart'; // Assuming DashboardScreen is in main.dart

/// Configuration for API endpoints.
class AppConfig {
  static const String baseUrl = 'http://192.168.100.22:8080/librareadsmob';
  static const String booksEndpoint = '$baseUrl/lib/books.php';
  static const String bookContentEndpoint = '$baseUrl/lib/book_contents.php'; // Not directly used in CatalogScreen's PDF flow
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Map<String, dynamic>> books = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  /// Fetches book data from the API.
  ///
  /// Sets loading state, handles successful data parsing,
  /// and updates error messages or book list accordingly.
  Future<void> _fetchBooks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(AppConfig.booksEndpoint),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            // Ensure each item in the list is a Map<String, dynamic>
            books = (data['books'] as List<dynamic>?)
                    ?.map<Map<String, dynamic>>((item) {
                      if (item is Map<String, dynamic>) {
                        return item;
                      }
                      debugPrint('Warning: Non-Map item found in books list: $item');
                      return {}; // Return an empty map for invalid items
                    })
                    .where((item) => item.isNotEmpty) // Filter out empty maps
                    .toList() ??
                [];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load books';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please check your connection.';
        isLoading = false;
      });
      debugPrint('Error fetching books: $e');
    }
  }

  /// Displays an error [SnackBar] with a given [message].
  ///
  /// Includes a "Retry" action to re-fetch books.
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _fetchBooks,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        title: const Text(
          'Catalog',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchBooks,
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
              ? _buildErrorState()
              : books.isEmpty
                  ? _buildEmptyState()
                  : _buildBooksList(),
      // Add the BottomNavigationBar here
      bottomNavigationBar: BottomNavBarCatalog(),
    );
  }

  /// Builds the loading indicator state.
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFA28D4F)),
          SizedBox(height: 16),
          Text(
            'Loading books...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Builds the error message state with a retry button.
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'An error occurred',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA28D4F),
              foregroundColor: Colors.white, // Text color
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds the empty state when no books are available.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No books available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA28D4F),
              foregroundColor: Colors.white, // Text color
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  /// Builds the main list of books, categorized by difficulty.
  Widget _buildBooksList() {
    return RefreshIndicator(
      onRefresh: _fetchBooks,
      color: const Color(0xFFA28D4F), // Color of the refresh indicator
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          _buildCategorySection('Beginner'),
          const SizedBox(height: 24),
          _buildCategorySection('Intermediate'),
          const SizedBox(height: 24),
          _buildCategorySection('Expert'),
          const SizedBox(height: 24),
          _buildCategoriesGrid(),
          const SizedBox(height: 100), // Provide space for bottom navigation bar
        ],
      ),
    );
  }

  /// Builds a horizontal scrollable section for a given book [category].
  Widget _buildCategorySection(String category) {
    List<Map<String, dynamic>> categoryBooks = books
        .where((book) =>
            book['category']?.toString().toLowerCase() == category.toLowerCase())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${categoryBooks.length} books',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Fixed height for horizontal ListView
          child: categoryBooks.isEmpty
              ? const Center(
                  child: Text(
                    'No books available in this category',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoryBooks.length,
                  itemBuilder: (context, index) {
                    final book = categoryBooks[index];
                    return _buildBookCard(book);
                  },
                ),
        ),
      ],
    );
  }

  /// Builds a [Card] widget to display individual book details.
  ///
  /// Navigates to [BookReadingScreen] when tapped, passing relevant book data.
  Widget _buildBookCard(Map<String, dynamic> book) {
    // Standardize cover image path: Assume API returns just the filename.
    final String coverImageFileName = book['cover_image_url']?.toString() ?? 'placeholder_default.jpg';
    final String assetImagePath = 'assets/covers/$coverImageFileName';

    debugPrint('Building card for book: ${book['title']}');
    debugPrint('FINAL IMAGE PATH FOR ${book['title']}: $assetImagePath');

    final bool isComplete = book['is_complete'] ?? false;
    final int totalChunks = book['total_chunks'] ?? 0;
    final int actualChunks = book['actual_chunks'] ?? 0;

    return Semantics(
      label: 'Book: ${book['title'] ?? 'Unknown Title'} by ${book['author'] ?? 'Unknown Author'}',
      button: true,
      child: GestureDetector(
        onTap: () {
          final String pdfUrl = book['pdf_file_url']?.toString() ?? '';
          final int bookId = book['id'] is int ? book['id'] : (int.tryParse(book['id']?.toString() ?? '0') ?? 0);

          if (pdfUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookReadingScreen(
                  bookTitle: book['title'] ?? 'Unknown Title',
                  bookAuthor: book['author'] ?? 'Unknown Author',
                  bookImage: assetImagePath, // Pass the corrected asset path
                  bookFileUrl: pdfUrl,
                  bookId: bookId,
                ),
              ),
            );
          } else {
            _showErrorSnackBar('PDF file not available for this book.');
          }
        },
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover image area with overlay
              Expanded(
                flex: 3,
                child: ClipRRect( // Added ClipRRect to ensure borderRadius works with Stack children
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image(
                          image: AssetImage(assetImagePath), // Use the correctly constructed path
                          fit: BoxFit.cover,
                          // Handle errors loading the specific image (e.g., file not found)
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading cover image for book ${book['title']}: $error');
                            return Container(
                              color: Colors.grey[800], // Dark background for placeholder
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey, size: 50), // Generic icon
                              ),
                            );
                          },
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        // "INCOMPLETE" label if the book is not complete
                        child: Stack( // Nested Stack for the label's positioning
                          children: [
                            if (!isComplete)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'INCOMPLETE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Book information area (title, author, progress)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1D29),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start, // SOLVED RENDERFLEX OVERFLOW: Changed to start
                    children: [
                      Text(
                        book['title'] ?? 'Unknown Title',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book['author'] ?? 'Unknown Author',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Display chapter progress if totalChunks is greater than 0
                      if (totalChunks > 0)
                        Text(
                          '$actualChunks/$totalChunks chapters',
                          style: TextStyle(
                            color: isComplete ? const Color(0xFFA28D4F) : Colors.orange,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a grid of programming language categories.
  Widget _buildCategoriesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Programming Languages',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildCategoryCard('assets/images/python.jpg', 'PYTHON'),
            _buildCategoryCard('assets/images/html.jpg', 'HTML'),
            _buildCategoryCard('assets/images/java.jpg', 'JAVA'),
            _buildCategoryCard('assets/images/cplus.jpg', 'C++'),
            _buildCategoryCard('assets/images/php.jpg', 'PHP'),
            _buildCategoryCard('assets/images/mysql.png', 'MYSQL'),
          ],
        ),
      ],
    );
  }

  /// Builds a [Card] for a programming language category.
  Widget _buildCategoryCard(String imagePath, String title) {
    return GestureDetector(
      onTap: () {
        _showCategoryBooks(title);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath, // Use the provided imagePath directly
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading category image $imagePath: $error');
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a modal bottom sheet with books filtered by the given [category].
  void _showCategoryBooks(String category) {
    // Revised filter logic: Only filter by the 'category' field for an exact match.
    List<Map<String, dynamic>> filteredBooks = books.where((book) {
      final bookCategory = book['category']?.toString().toLowerCase() ?? '';
      final searchTerm = category.toLowerCase();
      return bookCategory == searchTerm;
    }).toList();

    // If the category clicked is a programming language, we also want to show books where
    // the programming language is mentioned in the title, author, or the 'category' field itself.
    // This provides a broader search when clicking on programming language cards.
    if (['python', 'html', 'java', 'c++', 'php', 'mysql'].contains(category.toLowerCase())) {
      filteredBooks = books.where((book) {
        final title = book['title']?.toString().toLowerCase() ?? '';
        final bookCategory = book['category']?.toString().toLowerCase() ?? '';
        final author = book['author']?.toString().toLowerCase() ?? '';
        final searchTerm = category.toLowerCase();

        return title.contains(searchTerm) ||
               bookCategory.contains(searchTerm) ||
               author.contains(searchTerm);
      }).toList();
    }


    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F111D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar for the modal sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$category Books (${filteredBooks.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredBooks.isEmpty
                    ? const Center(
                        child: Text(
                          'No books found for this category',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(filteredBooks[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class BottomNavBarCatalog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F111D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFA28D4F),
        unselectedItemColor: Colors.grey,
        iconSize: 30,
        elevation: 0,
        onTap: (index) {
          String currentRoute = ModalRoute.of(context)!.settings.name ?? '';

          if (index == 0 && currentRoute != 'dashboard') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => DashboardScreen()));
          } else if (index == 1 && currentRoute != 'catalog') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => CatalogScreen()));
          } else if (index == 2 && currentRoute != 'my_books') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MyBooksScreen()));
          } else if (index == 3 && currentRoute != 'profile') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/logo.png', width: 30),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book, size: 30),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border, size: 30),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 30),
            label: '',
          ),
        ]
      ),
    );
  }
}