import 'package:flutter/material.dart';
import 'package:librareads1/profile.dart';
import 'dart:async';
import 'catalog.dart';
import 'mybooks.dart';
import 'landingpage.dart';
import 'api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'pdf_viewer.dart';
import 'package:librareads1/notification.dart';
import 'package:url_launcher/url_launcher.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String imagePath;
  final String description;
  final String category;
  final int pageCount;
  final String pdfAssetPath;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.imagePath,
    required this.description,
    required this.category,
    required this.pageCount,
    required this.pdfAssetPath,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      imagePath: json['imagePath'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      pageCount: json['pageCount'] as int,
      pdfAssetPath: json['pdfAssetPath'] as String,
    );
  }
}

Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    throw 'Could not launch $url';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.initClient();
  await ApiClient.instance.loadAuthToken();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LibraReads',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFA28D4F),
        scaffoldBackgroundColor: const Color(0xFF0F111D),
      ),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('logged_in') ?? false;

      Widget destinationPage;
      if (isLoggedIn) {
        destinationPage = const DashboardScreen();
      } else {
        destinationPage = const LandingPage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => destinationPage,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121921),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 200),
            const SizedBox(height: 20),
            const Text(
              'Welcome to LibraReads',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'AbhayaLibre',
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final int _initialPage = 0;
  late final PageController _pageController;
  int _currentPage = 0;

  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Book> _dummyBooks = [
    Book(
      id: '10012',
      title: 'Think Python',
      author: 'Allen B. Downey',
      imagePath: 'assets/cover/ThinkPython.jpg',
      description: 'An introduction to Python programming for beginners.',
      category: 'Python',
      pageCount: 244,
      pdfAssetPath: 'assets/pdfs/10012.pdf',
    ),
    Book(
      id: '10023',
      title: 'Think Data Structures',
      author: 'Allen B. Downey',
      imagePath: 'assets/cover/ThinkDataStructures.jpg',
      description: 'A practical introduction to data structures and algorithms.',
      category: 'Java',
      pageCount: 187,
      pdfAssetPath: 'assets/pdfs/10023.pdf',
    ),
    Book(
      id: '10022',
      title: 'Linux 101 Hacks',
      author: 'Ramesh Natarajan',
      imagePath: 'assets/cover/Linux101Hacks.jpg',
      description: 'Practical Linux tips, tricks, and hacks.',
      category: 'Linux',
      pageCount: 271,
      pdfAssetPath: 'assets/pdfs/10022.pdf',
    ),
    Book(
      id: '10006',
      title: 'Modern C',
      author: 'Jens Gustedt',
      imagePath: 'assets/cover/ModernC.jpg',
      description: 'A comprehensive guide to modern C programming.',
      category: 'C',
      pageCount: 324,
      pdfAssetPath: 'assets/pdfs/10006.pdf',
    ),
    Book(
      id: '10001',
      title: 'Modern C++ Tutorials',
      author: 'Ou Changkun',
      imagePath: 'assets/cover/ModernC++Tutorials.jpg',
      description: 'Tutorials for modern C++ features and best practices.',
      category: 'C++',
      pageCount: 92,
      pdfAssetPath: 'assets/pdfs/10001.pdf',
    ),
    Book(
      id: '10015',
      title: 'Exploring JavaScript',
      author: 'Dr. Axel Rauschmayer',
      imagePath: 'assets/cover/ExploringJavascript.jpg',
      description: 'In-depth exploration of JavaScript language features.',
      category: 'JavaScript',
      pageCount: 405,
      pdfAssetPath: 'assets/pdfs/10015.pdf',
    ),
    Book(
      id: '10013',
      title: 'Think Python V2',
      author: 'Allen l. Holub',
      imagePath: 'assets/cover/ThinkPythonv2.jpg',
      description: 'An updated version of Think Python for Python 2.',
      category: 'Python',
      pageCount: 244,
      pdfAssetPath: 'assets/pdfs/10013.pdf',
    ),
    Book(
      id: '10002',
      title: 'Introduction to Machine Learning with Python',
      author: 'Andreas C. Müller & Sarah Guido',
      imagePath: 'assets/cover/Introduction to ML with Python.png',
      description: 'A hands-on guide to Machine Learning with Python.',
      category: 'Python',
      pageCount: 392,
      pdfAssetPath: 'assets/pdfs/10002.pdf',
    ),
    Book(
      id: '10003',
      title: 'Effective Modern C++',
      author: 'Scott Meyers',
      imagePath: 'assets/cover/EffectiveModernC++.jpg',
      description: 'A deep dive into optimizing and writing effective C++ code.',
      category: 'C++',
      pageCount: 451,
      pdfAssetPath: 'assets/pdfs/10003.pdf',
    ),
    Book(
      id: '10009',
      title: 'Algorithms in C',
      author: 'Robert Sedgewick',
      imagePath: 'assets/cover/AlgorithmsinC.jpeg',
      description: 'Comprehensive coverage of algorithms implemented in C.',
      category: 'C',
      pageCount: 672,
      pdfAssetPath: 'assets/pdfs/10009.pdf',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.55,
      initialPage: _initialPage,
    );

    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });

    _allBooks = _dummyBooks;
    _filteredBooks = List.from(_allBooks);

    _searchController.addListener(_filterBooks);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBooks);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _filterBooks() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = List.from(_allBooks);
      } else {
        _filteredBooks = _allBooks.where((book) {
          return book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query) ||
              book.category.toLowerCase().contains(query);
        }).toList();
      }
      if (_filteredBooks.isNotEmpty) {
        _pageController.jumpToPage(0);
        _currentPage = 0;
      } else {
        _currentPage = 0;
      }
    });
  }

   _showAppVersionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: const Color(0xFF121921),
          title: const Text(
            'App Version',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'LibraReads v1.0.0 (Build 20250608)',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Color(0xFFA28D4F))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CatalogScreen(),
              settings: const RouteSettings(name: 'catalog'),
            ),
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MyBooksScreen(),
              settings: const RouteSettings(name: 'my_books'),
            ),
          );
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileScreen(),
              settings: const RouteSettings(name: 'profile'),
            ),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121921),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: const Text(
                'LibraReads',
                style: TextStyle(
                  fontSize: 30,
                  fontFamily: 'AbhayaLibre',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFFA28D4F),
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF121921),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFA28D4F),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/logob.png', height: 150),
                    const SizedBox(height: 10),
                    const Text(
                      'LibraReads',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AbhayaLibre',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Your Digital Library',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                      ),
                       textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  buildDrawerItem(Icons.info_outline, 'About Us', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                    );
                  }),
                  buildDrawerItem(Icons.star_rate, 'Rate App', () {
                    Navigator.pop(context);
                    _launchURL('https://play.google.com/store/apps/details?id=com.yourcompany.librareads');
                  }),
                  buildDrawerItem(Icons.verified_user, 'Privacy Policy', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                    );
                  }),
                  buildDrawerItem(Icons.info, 'App Version', () {
                    Navigator.pop(context);
                    _showAppVersionDialog(context);
                  }),
                  const Divider(color: Colors.white24, height: 30, thickness: 1),
                  buildDrawerItem(Icons.logout, 'Logout', () async {
                    Navigator.pop(context);
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('logged_in', false);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()), 
                      (Route<dynamic> route) => false,
                    );
                  }),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '© LibraReads 2025. All rights reserved.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Welcome Back, ',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: 'mate!',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.66,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    const Text(
                      'BOOK RECOMMENDATIONS FOR YOU',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'PlayfairDisplay',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_filteredBooks.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121921),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _filteredBooks[_currentPage % _filteredBooks.length].title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _filteredBooks[_currentPage % _filteredBooks.length].author,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (_filteredBooks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No books found matching your search.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _filteredBooks.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            double scale = (1 - (index - _currentPage).abs() * 0.2).clamp(0.8, 1.0);
                            final book = _filteredBooks[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 25 - (scale * 10)),
                              child: Transform.scale(
                                scale: scale,
                                child: Column(
                                  children: [
                                    BookCard(
                                      book: book,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookDetailScreen(book: book),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFA28D4F),
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Montserrat',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: Container(
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
            currentIndex: _selectedIndex,
            iconSize: 28,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  'assets/logo.png',
                  width: 28,
                  color: _selectedIndex == 0 ? const Color(0xFFA28D4F) : Colors.grey[600],
                ),
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
      ),
    );
  }

  Widget buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          highlightColor: Colors.white10,
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFA28D4F), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 240,
          height: 330,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(book.imagePath),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.title,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          book.author,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121921),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          book.title,
          style: const TextStyle(
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 400,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(book.imagePath),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'PlayfairDisplay',
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'by ${book.author}',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailChip(Icons.category, book.category),
                  _buildDetailChip(Icons.pages, '${book.pageCount} pages'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                book.description,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfViewerScreen(
                        pdfPath: book.pdfAssetPath,
                        bookTitle: book.title,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.book, color: Colors.black),
                label: const Text(
                  'Read Book',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA28D4F),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, color: Colors.black87, size: 20),
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: const Color(0xFFA28D4F).withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search books...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1C1F2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }
}
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121921),
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/logo.png',
                height: 140,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to LibraReads!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'LibraReads is a digital library app designed to provide easy and affordable access to a wide range of e-book collections focused on technology, with a primary emphasis on programming languages. LibraReads aims to simplify users access to high-quality, diverse programming learning resources, helping them expand their knowledge and skills to tackle the challenges of the digital era.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              'Our Vision',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We envision a future where this app empowers readers to easily access information and expand their knowledge, enabling them to better prepare for the challenges of the ever-evolving digital era.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              'What We Offer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. A continually growing library of e-books.\n'
              '2. Intuitive search and discovery features.\n'
              '3. Personalized recommendations.\n'
              '4. A seamless reading experience across devices.\n'
              '5. Tools to manage your personal bookshelf.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.8,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Thank you for being a part of the LibraReads community!',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                '© 2025 LibraReads. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121921),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'AbhayaLibre',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Privacy Matters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'At LibraReads, we are committed to protecting your privacy. This Privacy Policy explains how we collect, use, and disclose information about you when you use our mobile application ("App").',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Information We Collect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We collect information to provide and improve our services. This includes:\n'
              '1. Personal Information: When you register, we may collect your name, email address, and other contact details.\n'
              '2. Usage Data: Information about how you access and use the App, suchs as pages visited, time spent, and books read.\n'
              '3. Device Information: Details about your device, including IP address, operating system, and unique device identifiers.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.8,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              '2. How We Use Your Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We use the collected information for various purposes, including to:\n'
              '1. Provide and maintain the App.\n'
              '2. Personalize your reading experience.\n'
              '3. Improve our services and develop new features.\n'
              '4. Communicate with you about updates, promotions, and important notices.\n'
              '5. Monitor and analyze usage trends.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.8,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              '3. Disclosure of Your Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We may share your information with third parties only in the following circumstances:\n'
              '1. With Your Consent: When you give us explicit permission.\n'
              '2. For Service Providers: To third-party vendors who perform services on our behalf (e.g., hosting, analytics).\n'
              '3. For Legal Reasons: To comply with legal obligations or protect our rights and safety.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.8,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              '4. Data Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We implement reasonable security measures to protect your information from unauthorized access, alteration, disclosure, or destruction. However, no internet transmission or electronic storage is 100% secure.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              '5. Changes to This Privacy Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'PlayfairDisplay',
                color: Color(0xFFA28D4F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. You are advised to review this Privacy Policy periodically for any changes.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Montserrat',
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'If you have any questions about this Privacy Policy, please contact us.',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Last updated: June 8, 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}