import 'package:flutter/material.dart';
import 'main.dart';
import 'catalog.dart';
import 'profile.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({Key? key}) : super(key: key);

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  final List<Map<String, String>> books = [
    {'title': 'Extreme C', 'author': 'Kamran Amini', 'image': 'assets/ExtremeC.png'},
    {'title': 'SQL Cookbook', 'author': 'Anthony Molinaro', 'image': 'assets/SQLCookbook.png'},
    {'title': 'Effective Modern C++', 'author': 'Scott Meyers', 'image': 'assets/EffectiveModernC++.png'},
    {'title': 'Exploring JavaScript', 'author': 'Dr. Axel Rauschmayer', 'image': 'assets/ExploringJavaScript.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Bookshelf',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Books (${books.length})',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: books.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {},
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      color: const Color(0xFF121921),
                      child: Column(
                        children: [
                          Expanded(
                      child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          books[index]['image']!,
                          fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  books[index]['title']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  books[index]['author']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Roboto',
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
      bottomNavigationBar: Container(
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
          selectedItemColor: const Color(0xFFA28D4F),
          unselectedItemColor: Colors.grey,
          iconSize: 30,
          elevation: 0,
          onTap: (index) {
            String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

            if (index == 0 && currentRoute != 'dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            } else if (index == 1 && currentRoute != 'catalog') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CatalogScreen()),
              );
            } else if (index == 2 && currentRoute != 'my_books') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MyBooksScreen()),
              );
            } else if (index == 3 && currentRoute != 'profile') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
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
          ],
        ),
      ),
    );
  }
}
