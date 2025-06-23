import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'main.dart';
import 'catalog.dart';
import 'profile.dart';
import 'reading.dart';
import 'books.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({Key? key}) : super(key: key);

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> with WidgetsBindingObserver {
  List<Book> _savedBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedBooks();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSavedBooks();
    }
  }

  Future<void> _loadSavedBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedBookIds = prefs.getStringList('savedBookIds') ?? [];

      if (savedBookIds.isEmpty) {
        setState(() {
          _isLoading = false;
          _savedBooks = [];
        });
        return;
      }

      List<Book> loadedBooks = [];
      for (String id in savedBookIds) {
        final book = allBooks.firstWhere(
          (b) => b.id == id,
          orElse: () {
            debugPrint('Book with ID $id not found in local allBooks. It might have been removed or is a legacy ID.');
            return Book(
              id: id,
              title: 'Unknown Book',
              author: 'Unknown Author',
              imagePath: 'assets/cover/placeholder_default.jpg',
              description: 'This book could not be found locally.',
              category: '',
              pageCount: 0,
              pdfAssetPath: '',
            );
          },
        );
        loadedBooks.add(book);
      }

      setState(() {
        _savedBooks = loadedBooks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading your bookshelf. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading saved books from SharedPreferences or allBooks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        centerTitle: true,
        leading: null,
        title: const Text(
          'BookShelf',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: const <Widget>[],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BookShelf (${_savedBooks.length})',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                    ? _buildErrorState(_errorMessage)
                    : _savedBooks.isEmpty
                        ? _buildEmptyState()
                        : Expanded(
                            child: GridView.builder(
                              itemCount: _savedBooks.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.7,
                              ),
                              itemBuilder: (context, index) {
                                final book = _savedBooks[index];
                                return _buildSavedBookCard(book);
                              },
                            ),
                          ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarMyBooks(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFA28D4F)),
          SizedBox(height: 16),
          Text(
            'Loading your books...',
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 72,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSavedBooks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA28D4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
            ),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
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
            Icons.bookmark_border,
            size: 72,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'No books saved yet!\nDiscover new books in the Catalog.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontFamily: 'Montserrat',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CatalogScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA28D4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
            ),
            icon: const Icon(Icons.search),
            label: const Text(
              'Explore Catalog',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedBookCard(Book book) {
    final bool isLocalImage = book.imagePath.startsWith('assets/');
    final String placeholderAssetPath = 'assets/cover/placeholder_default.jpg';

    return Semantics(
      label: 'Book: ${book.title} by ${book.author}',
      button: true,
      child: GestureDetector(
        onTap: () async {
          if (book.pdfAssetPath.isNotEmpty) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookReadingScreen(
                  bookTitle: book.title,
                  bookAuthor: book.author,
                  bookImage: book.imagePath,
                  bookFileUrl: book.pdfAssetPath,
                  bookId: book.id,
                ),
              ),
            );
            _loadSavedBooks();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PDF file not available for this book.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(4, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1D29),
                const Color(0xFF0F111D).withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: isLocalImage
                            ? Image.asset(
                                book.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Error loading MyBooks asset image: $error');
                                  return Image.asset(
                                    placeholderAssetPath,
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : CachedNetworkImage(
                                imageUrl: book.imagePath,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFA28D4F)),
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('Error loading MyBooks network image: $error');
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
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
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
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          book.author,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontFamily: 'Poppins',
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
          currentIndex: 2,
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
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (context) => const CatalogScreen()));
            } else if (index == 2) {
              // Already on MyBooksScreen
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