import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'main.dart';
import 'catalog.dart';
import 'mybooks.dart';
import 'editprofile.dart';
import 'landingpage.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  String _userName = "Marta";
  String _username = "martaaaa";
  String _password = "password123";
  String _selectedLanguage = "English"; // Default selected language

  final ImagePicker _picker = ImagePicker();
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LandingPage()));
  }

  void _editProfile() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userName,
          currentUsername: _username,
          currentPassword: _password,
        ),
      ),
    );
    if (updatedData != null) {
      setState(() {
        _userName = updatedData['name'];
        _username = updatedData['username'];
        _password = updatedData['password'];
      });
    }
  }

  void _openHelpCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1F212F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Help Center", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              leading: Icon(Icons.help_outline, color:Color(0xFFA28D4F)),
              title: Text("FAQ", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSimpleDialog("FAQ", "Q: How to borrow a book?\nA: Go to Catalog > Select Book > Borrow.");
              },
            ),
            ListTile(
              leading: Icon(Icons.contact_mail_outlined, color: Color(0xFFA28D4F)),
              title: Text("Contact Support", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSimpleDialog("Contact Support", "Email us at support@librareads.com");
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1F212F),
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: Text(content, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: Text("OK", style: TextStyle(color:Color(0xFFA28D4F))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1F212F),
        title: Text("Select Language", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("English", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedLanguage = "English";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Spanish", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedLanguage = "Spanish";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("French", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedLanguage = "French";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("German", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedLanguage = "German";
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Chinese", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  _selectedLanguage = "Chinese";
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color:Color(0xFFA28D4F))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

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
          'Settings',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : AssetImage('assets/pp.jpg') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFA28D4F),
                        child: Icon(Icons.edit, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(_userName, style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text("Profile", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: _editProfile,
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.white),
              title: const Text("Privacy & Security", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () => _showSimpleDialog("Privacy & Security", "Your data is safe and encrypted."),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.notifications_none, color: Colors.white),
              title: const Text("Notifications", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: () => _showSimpleDialog("Notifications", "All notification settings go here."),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.white),
              title: const Text("Help Center", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: _openHelpCenter,
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white),
              title: Text("Languages: $_selectedLanguage", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: _selectLanguage,
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
              onTap: _logout,
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
          selectedItemColor: Color(0xFFA28D4F),
          unselectedItemColor: Colors.grey,
          iconSize: 30,
          elevation: 0,
          onTap: (index) {
            String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

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
          ],
        ),
      ),
    );
  }
}
