import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'mybooks.dart';
import 'profile.dart';
import 'reading.dart';
import 'main.dart';
import 'books.dart';
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Book> books = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocalBooks();
  }

  Future<void> _loadLocalBooks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      books = allBooks;
      isLoading = false;
      if (books.isEmpty) {
        errorMessage = 'No books available locally.';
      }
    });

    if (errorMessage != null && mounted) {
      _showErrorSnackBar(errorMessage!);
    }
  }

  /// Displays an error [SnackBar] with a given [message].
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Montserrat',
            ),
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
              ? _buildErrorState()
              : books.isEmpty
                  ? _buildEmptyState()
                  : _buildBooksList(),
      bottomNavigationBar: const BottomNavBarMyBooks(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFA28D4F)),
          const SizedBox(height: 20),
          Text(
            'Loading ..',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 30),
          Text(
            errorMessage ?? 'No books could be loaded.',
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 30),
          Text(
            'No books found in your local catalog.\nAdd some books to your assets!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildBooksList() {
    return RefreshIndicator(
      onRefresh: _loadLocalBooks,
      color: const Color(0xFFA28D4F),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 25),
          _buildCategorySection('Beginner', 'Perfect for those starting their coding journey.'),
          const SizedBox(height: 40),
          _buildCategorySection('Intermediate', 'Dive deeper with more complex concepts and projects.'),
          const SizedBox(height: 40),
          _buildCategorySection('Expert', 'Advanced topics for seasoned developers.'),
          const SizedBox(height: 40),
          _buildCategoriesGrid(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Builds a horizontal scrollable section for a given book [category].
  Widget _buildCategorySection(String category, String description) {
    List<Book> categoryBooks = books
        .where((book) =>
            book.category.toString().toLowerCase() == category.toLowerCase())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${categoryBooks.length} books available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 240,
          child: categoryBooks.isEmpty
              ? Center(
                  child: Text(
                    'No books available in the $category category yet.',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
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

  /// Navigates to [BookReadingScreen] when tapped, passing relevant book data.
  Widget _buildBookCard(Book book) {
    final String coverImageUrl = book.imagePath;
    final String placeholderAssetPath = 'assets/covers/placeholder_default.jpg';

    debugPrint('Building card for book: ${book.title}');
    debugPrint('FINAL IMAGE URL FOR ${book.title}: $coverImageUrl');

    return Semantics(
      label: 'Book: ${book.title} by ${book.author}',
      button: true,
      child: GestureDetector(
        onTap: () {
          final String pdfUrlToPass = book.pdfAssetPath;
          final String bookId = book.id;

          debugPrint('Tapped book: ${book.title}');
          debugPrint('PDF URL to pass: $pdfUrlToPass');
          debugPrint('Book ID to pass: $bookId');

          if (pdfUrlToPass.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookReadingScreen(
                  bookTitle: book.title,
                  bookAuthor: book.author,
                  bookImage: coverImageUrl,
                  bookFileUrl: pdfUrlToPass,
                  bookId: bookId,
                ),
              ),
            );
          } else {
            _showErrorSnackBar('PDF file not available for this book.');
          }
        },
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(5, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1D29),
                const Color(0xFF0F111D).withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: coverImageUrl.startsWith('assets/')
                            ? Image.asset(
                                coverImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                      'Error loading asset image for book ${book.title}: $error');
                                  return Image.asset(
                                    placeholderAssetPath,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : CachedNetworkImage(
                                imageUrl: coverImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                      color: const Color(0xFFA28D4F)),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint(
                                      'Error loading network image for book ${book.title}: $error');
                                  return Image.asset(
                                    placeholderAssetPath,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
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
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1D29),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins', // Applied custom font (no change)
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontFamily: 'Montserrat', // Applied custom font (no change)
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
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

  Widget _buildCategoriesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 15.0),
          child: Text(
            'Programming',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildCategoryCard('assets/images/python.jpg', 'PYTHON'),
            _buildCategoryCard('assets/images/html.jpg', 'HTML'),
            _buildCategoryCard('assets/images/java.jpg', 'JAVA'),
            _buildCategoryCard('assets/images/cplus.jpg', 'C++'),
            _buildCategoryCard('assets/images/php.jpg', 'PHP'),
            _buildCategoryCard('assets/images/mysql.png', 'MYSQL'),
            _buildCategoryCard('assets/images/c.jpg', 'C'),
            _buildCategoryCard('assets/images/JavaScript.png', 'JAVASCRIPT'),
            _buildCategoryCard('assets/images/NodeJS.png', 'NODEJS'),
            _buildCategoryCard('assets/images/LINUX.jpeg', 'LINUX'),
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 10),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1D29),
              const Color(0xFF0F111D).withOpacity(0.95),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading category image $imagePath: $error');
                  return Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 60),
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
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1.8,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 3),
                          blurRadius: 5,
                          color: Colors.black87,
                        ),
                      ],
                      fontFamily: 'Montserrat',
                    ),
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
    List<Book> filteredBooks;
    final String lowerCaseCategory = category.toLowerCase();

    final List<String> programmingLanguages = [
      'python',
      'html',
      'java',
      'c++',
      'php',
      'mysql',
      'c',
      'javascript',
      'nodejs',
      'linux'
    ];

    if (['beginner', 'intermediate', 'expert'].contains(lowerCaseCategory)) {
      filteredBooks = books.where((book) {
        final bookCategory = book.category.toString().toLowerCase();
        return bookCategory == lowerCaseCategory;
      }).toList();
    } else if (programmingLanguages.contains(lowerCaseCategory)) {
      filteredBooks = books.where((book) {
        final bookCategory = book.category.toString().toLowerCase();
        return bookCategory == lowerCaseCategory;
      }).toList();
    } else {
      filteredBooks = [];
      debugPrint('Warning: Attempted to filter by unknown category: $category');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D29),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 15,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                '${category.toUpperCase()} Books (${filteredBooks.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: filteredBooks.isEmpty
                    ? const Center(
                        child: Text(
                          'No books found for this category yet.\nCheck back later!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontFamily: 'Montserrat'
                              ),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
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


class BottomNavBarMyBooks extends StatelessWidget {
  const BottomNavBarMyBooks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF0F111D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFA28D4F),
          unselectedItemColor: Colors.grey[600],
          currentIndex: 1,
          iconSize: 28,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontFamily: 'Montserrat',
          ),
          elevation: 0,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
            } else if (index == 1) {
              //sudah di catalog
            } else if (index == 2) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const MyBooksScreen()));
            } else if (index == 3) {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset('assets/logo.png', width: 28, color: Colors.grey[600]),
              activeIcon: Image.asset('assets/logo.png', width: 28, color: const Color(0xFFA28D4F)),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'Catalog',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark),
              label: 'BookShelf',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}