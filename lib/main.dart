import 'package:flutter/material.dart';
import 'package:librareads1/profile.dart';
import 'dart:async';
import 'catalog.dart';
import 'mybooks.dart';
import 'landingpage.dart';

void main() {
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
        primaryColor: Color(0xFFA28D4F),
        scaffoldBackgroundColor: const Color(0xFF0F111D),
      ),
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
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
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
    final int _initialPage = 5;
  late final PageController _pageController;
  int _currentPage = 5;

  final List<String> books = [
    'assets/ThinkPython.jpg',
    'assets/WebDevelopment.jpg',
    'assets/PHPbyExample.jpg',
    'assets/PythonDataAnalysis.jpg',
    'assets/MachineLearning.jpg',
    'assets/AppDevelopmentFlutter.jpg',
    'assets/ComputerProgramming.jpg',
    'assets/DataScience101.jpg',
    'assets/FunctionalProgramming.jpg',
    'assets/MasterCoding.jpg',
    'assets/PragmaticProgrammer.jpg'
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
}

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CatalogScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyBooksScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.notifications_none,
              color: Color(0xFFA28D4F),
              size: 30,
            ),
          ),
        ],
      ),
    ),
    drawer: Drawer(
      backgroundColor: Color(0xFFF5F5F5),
      child: Column(
        children: [
          Container(
            color: const Color(0xFF121921),
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            width: double.infinity,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40, backgroundColor: Colors.white,
      child: CircleAvatar(
          radius: 80, backgroundImage: AssetImage('assets/pp.jpg'),
      ),
    ),
    const SizedBox(height: 10),
    const Text(
      'Marta',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', color: Colors.white,
        ),
      ),
    const Text(
      'kelompok9@gmail.com',
      style: TextStyle(fontSize: 14,fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white70,
        ),
      ),
    ],
  ),
),
      const SizedBox(height: 20),
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            buildDrawerItem(Icons.history, 'Reading History', () {
              Navigator.pop(context);
            }),
            const Divider(),
            buildDrawerItem(Icons.new_releases, 'New Releases', () {
              Navigator.pop(context);
            }),
            const Divider(),
            buildDrawerItem(Icons.palette, 'Themes', () {
              Navigator.pop(context);
            }),
            const Divider(),
            buildDrawerItem(Icons.info_outline, 'About Us', () {
              Navigator.pop(context);
            }),
            const Divider(),
            buildDrawerItem(Icons.exit_to_app, 'Logout', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LandingPage()),
              );
            }),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(bottom: 30, top: 10),
        child: Text(
          '© 2025 LibraReads\nVersion 1.0.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
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
                    style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                  TextSpan(
                  text: 'mate!',
                    style: TextStyle(fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.white,
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
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)), filled: true,
                fillColor: Colors.white.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Icon(
                Icons.search, color: Colors.white.withOpacity(0.7),
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
                  'BEGIN YOUR READING JOURNEY',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
          decoration: BoxDecoration(
            color: Color(0xFF121921),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                getBookTitle(_currentPage),
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
                getBookAuthor(_currentPage),
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

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: books.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    double scale = (1 - (index - _currentPage).abs() * 0.2).clamp(0.8, 1.0);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 25 - (scale * 10)),
                      child: Transform.scale(
                        scale: scale,
                        child: Column(
                          children: [
                            BookCard(books[index], getBookAuthor(index)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CatalogScreen(),
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
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        selectedItemColor: Color(0xFFA28D4F),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
              icon: Image.asset('assets/logo.png', width: 30), label: ''),
          const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book, size: 30), label: ''),
          const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border, size: 30), label: ''),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 30), label: ''),
        ],
      ),
      )
    );
  }

  Widget buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color:Color(0xFFA28D4F)),
      title: Text(title,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Montserrat',
        fontSize: 16,
        fontWeight: FontWeight.bold,
      )
    ),
    onTap: onTap,
    );
  }

  String getBookTitle(int index) {
    List<String> titles = [
      'Think Python',
      'Web Development',
      'PHP by Example',
      'Python Data Analysis',
      'Machine Learning',
      'App Development Flutter',
      'Computer Programming',
      'Data Science 101',
      'Functional Programming',
      'Master Coding',
      'Pragmatic Programmer'
    ];
    return titles[index % titles.length];
  }


  String getBookAuthor(int index) {
    List<String> authors = [
      'Allen B. Downey',
      'White Belt Mastery',
      'Alex Vasilev',
      'Alex Campbell',
      'Michael Krauss',
      'Rap Payne',
      'Alexander Bell',
      'Andrew Park',
      'Dimitris Papadimitriou',
      'Aef Saeful',
      'David Thomas, Andrew Hunt'
    ];
    return authors[index % authors.length];
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

class BookCard extends StatelessWidget {
  final String imagePath;
  final String author;
  const BookCard(this.imagePath, this.author, {super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 240,
          height: 330,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Text(author,
            style: const TextStyle(fontSize: 12, fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color : Color.fromARGB(255, 0, 0, 0))),
      ],
    );
  }
}