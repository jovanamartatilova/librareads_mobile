import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentUsername;
  final String currentPassword;

  EditProfileScreen({
    required this.currentName,
    required this.currentUsername,
    required this.currentPassword,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  File? _imageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.currentName);
    _usernameController = TextEditingController(text: widget.currentUsername);
    _passwordController = TextEditingController(text: widget.currentPassword);
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void saveChanges() {
    Navigator.pop(context, {
      'name': _nameController.text,
      'username': _usernameController.text,
      'password': _passwordController.text,
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await uploadProfilePicture(_imageFile!);
    }
  }

Future<void> uploadProfilePicture(File imageFile) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');

  if (userId == null) {
    print("User belum login.");
    return;
  }

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://192.168.214.226/librareadsmob/lib/updateprofilepicture.php'),
  );

  request.fields['user_id'] = userId.toString();
  request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

  var response = await request.send();

  if (response.statusCode == 200) {
    print('Upload foto berhasil');
  } else {
    print('Upload foto gagal');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.edit, size: 16, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
