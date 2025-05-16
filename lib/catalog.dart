import 'package:flutter/material.dart';
import 'main.dart';
import 'mybooks.dart';
import 'profile.dart';
import 'reading.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C2B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white54),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search books...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onChanged: (query) {
                    print('User is searching: $query');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          const Text(
            'Hot Picks for Coders',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                recentBookCard('assets/WebDevelopment.jpg', 'Web Development', context),
                recentBookCard('assets/PHPbyExample.jpg', 'PHP by Example', context),
                recentBookCard('assets/PythonDataAnalysis.jpg', 'Python Data Analysis', context),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Most Borrowed This Month',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                myBookCard('assets/ComputerProgramming.jpg', 'Computer Programming', context),
                myBookCard('assets/FunctionalProgramming.jpg', 'Functional Programming', context),
                myBookCard('assets/PragmaticProgrammer.jpg', 'Pragmatic Programmer', context),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'New Arrivals',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                wishBookCard('assets/MachineLearning.jpg', 'Machine Learning', context),
                wishBookCard('assets/ThinkPython.jpg', 'Think Python', context),
                wishBookCard('assets/CodingAbsoluteBeginners.jpg', 'Coding Absolute Beginners', context),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              categoryCard('assets/python.jpg', 'PYTHON'),
              categoryCard('assets/html.jpg', 'HTML'),
              categoryCard('assets/java.jpg', 'JAVA'),
              categoryCard('assets/cplus.jpg', 'C++'),
              categoryCard('assets/php.jpg', 'PHP'),
              categoryCard('assets/mysql.png', 'MYSQL'),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBarCatalog(),
    );
  }
}

Widget recentBookCard(String image, String title, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReadingScreen(bookTitle: title, bookImage: image),
        ),
      );
    },
    child: Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

Widget myBookCard(String image, String title, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReadingScreen(bookTitle: title, bookImage: image),
        ),
      );
    },
    child: Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
      ),
    ),
  );
}

Widget wishBookCard(String image, String title, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookReadingScreen(bookTitle: title, bookImage: image),
        ),
      );
    },
    child: Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(8)),
          child:
              const Icon(Icons.bookmark_border, color: Colors.white, size: 16),
        ),
      ),
    ),
  );
}

Widget categoryCard(String image, String title, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
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
              image,
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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



