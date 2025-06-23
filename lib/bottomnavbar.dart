import 'package:flutter/material.dart';
import 'main.dart';
import 'catalog.dart';
import 'profile.dart';
import 'mybooks.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

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
          currentIndex: currentIndex,
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
            String currentRouteName = ModalRoute.of(context)?.settings.name ?? '';

            if (index == 0 && currentRouteName != '/dashboard') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                  settings: const RouteSettings(name: '/dashboard'),
                ),
              );
            } else if (index == 1 && currentRouteName != '/catalog') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CatalogScreen(),
                  settings: const RouteSettings(name: '/catalog'),
                ),
              );
            } else if (index == 2 && currentRouteName != '/my_books') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyBooksScreen(),
                  settings: const RouteSettings(name: '/my_books'),
                ),
              );
            } else if (index == 3 && currentRouteName != '/profile') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                  settings: const RouteSettings(name: '/profile'),
                ),
              );
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