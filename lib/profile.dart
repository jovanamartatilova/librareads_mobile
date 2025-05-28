import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:dio/dio.dart';

// Impor ApiClient terpusat kita
import 'api_client.dart';

// Impor layar Anda yang lain
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
  // State variables
  File? _imageFile;
  String? _profileImageUrl;
  String _userName = "Loading...";
  String _selectedLanguage = "English";

  // Helpers and controllers
  final ImagePicker _picker = ImagePicker(); // <-- INI YANG BENAR

  // HAPUS SEMUA VARIABEL DAN FUNGSI DIO LOKAL
  // late Dio _dio;
  // PersistCookieJar? _cookieJar;
  // final String _apiBaseUrl = "...";
  // Future<void> _initializeDioAndLoadData() async { ... }
  // Future<void> _initializeCookieJar() async { ... }

  @override
  void initState() {
    super.initState();
    // Langsung panggil _loadUserData karena ApiClient sudah diinisialisasi di main.dart
    _loadUserData();
  }

  void _loadUserData() async {
    // Dapatkan instance dio yang sudah siap pakai dari ApiClient
    final dio = ApiClient.instance.dio;

    // Muat data dari SharedPreferences sebagai fallback awal
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('name') ?? "User";
      });
    }

    try {
      // Gunakan dio dari ApiClient dan cukup sebutkan nama file PHP-nya
      print("Mencoba mengambil profil dari endpoint: get_profile.php");
      final response = await dio.get('get_profile.php');

      print('Status respons profil: ${response.statusCode}');
      print('Body respons profil: ${response.data}');

      if (mounted && response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          setState(() {
            _userName = data['full_name'] ?? _userName;
            _profileImageUrl = data['profile_picture_url'];
            _imageFile = null;
          });
          await prefs.setString('name', _userName);
        } else if (data['message']?.contains('Unauthorized')) {
          _logout(showLoginMessage: true);
        } else {
          print('Error dari server (get_profile): ${data['message']}');
        }
      } else if (mounted) {
        print('Error server saat mengambil profil: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Error jaringan saat mengambil profil: $e');
      if (e.response?.statusCode == 401 && mounted) {
        _logout(showLoginMessage: true);
      }
    }
  }

  Future<void> _logout({bool showLoginMessage = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Gunakan cookieJar dari ApiClient untuk menghapus cookie
    await ApiClient.instance.cookieJar.deleteAll();
    print("Cookie telah dihapus melalui ApiClient saat logout.");

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LandingPage()),
        (Route<dynamic> route) => false,
      );
      if (showLoginMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi telah berakhir. Silakan login kembali.')),
        );
      }
    }
  }

  void _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImageUrl = null;
      });
      // TODO: Implementasikan fungsionalitas unggah gambar ke server menggunakan ApiClient
      // Contoh:
      // final dio = ApiClient.instance.dio;
      // FormData formData = FormData.fromMap({
      //   "profile_picture": await MultipartFile.fromFile(pickedFile.path),
      // });
      // final response = await dio.post('upload_profile.php', data: formData);
      print("Gambar dipilih. Fungsionalitas unggah belum diimplementasikan.");
    }
  }

  void _selectLanguage() async {
    final List<String> languages = ["English", "Spanish", "French", "German", "Chinese", "Indonesian"];

    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1F212F),
          title: Text("Select Language", style: TextStyle(color: Colors.white)),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(languages[index], style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context, languages[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Color(0xFFA28D4F))),
              onPressed: () => Navigator.pop(context, null),
            ),
          ],
        );
      },
    );

    if (selected != null && mounted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = selected;
      });
      await prefs.setString('language', _selectedLanguage);
    }
  }
  
  // Fungsi _editProfile, _openHelpCenter, _showSimpleDialog tetap sama...
  void _editProfile() {}
  void _openHelpCenter() {}
  void _showSimpleDialog(String title, String content) {}

  @override
  Widget build(BuildContext context) {
    ImageProvider displayImage;
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      displayImage = NetworkImage(_profileImageUrl!);
    } else if (_imageFile != null) {
      displayImage = FileImage(_imageFile!);
    } else {
      displayImage = AssetImage('assets/pp.jpg');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      // **FIX**: Bungkus dengan SingleChildScrollView untuk menghindari overflow
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: displayImage,
                      onBackgroundImageError: (exception, stackTrace) {
                        if (mounted) {
                          setState(() {
                            _profileImageUrl = null;
                            _imageFile = null;
                          });
                        }
                      },
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
              // Daftar menu settings...
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text("Profile", style: TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                onTap: _editProfile,
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
                onTap: () => _logout(showLoginMessage: false),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        // Kode BottomNavigationBar Anda di sini...
      ),
    );
  }
}