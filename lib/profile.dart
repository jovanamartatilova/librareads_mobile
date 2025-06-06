import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:librareads1/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'main.dart';
import 'catalog.dart';
import 'mybooks.dart';
import 'editprofile.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart' show MediaType;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  String? _profileImageUrl;
  String _userName = "Loading...";
  String _userEmail = "";
  String _selectedLanguage = "English";
  bool _isLoading = false;

  String? _userId;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSelectedLanguage();
  }

  void _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLanguage = prefs.getString('language') ?? "English";
      });
    }
  }

  void _loadUserData() async {
    final dio = ApiClient.instance.dio;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    if (mounted) {
      setState(() {
        _userName = prefs.getString('name') ?? "User";
        _userEmail = prefs.getString('email') ?? "";
        _profileImageUrl = prefs.getString('profile_picture');
        _userId = prefs.getString('user_id');  // <-- ambil user_id juga
      });
    }

    try {
      print("PROFILE_SCREEN: Mengambil profil dari endpoint: get_profile.php");
      final response = await dio.get('get_profile.php');

      print('PROFILE_SCREEN: Status respons: ${response.statusCode}');
      print('PROFILE_SCREEN: Body respons: ${response.data}');

      if (mounted && response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 'success') {
          if (_profileImageUrl != null && data['profile_picture_url'] != _profileImageUrl) {
          try {
            NetworkImage(_profileImageUrl!).evict();
          } catch (e) {
            print("Error evicting old image during load: $e");
          }
        }
          setState(() {
            _userName = data['username'] ?? _userName;
            _userEmail = data['email'] ?? _userEmail;
            String? newImageUrl = data['profile_picture_url'];
          if (newImageUrl != null && newImageUrl.isNotEmpty) {
            if (!newImageUrl.contains('?')) {
              newImageUrl += '?v=${DateTime.now().millisecondsSinceEpoch}';
            }
          }
            _profileImageUrl = newImageUrl;
            _imageFile = null;
          });
          
          // Simpan data terbaru ke SharedPreferences
          await prefs.setString('name', _userName);
          await prefs.setString('email', _userEmail);
          if (_profileImageUrl != null) {
            await prefs.setString('profile_picture', _profileImageUrl!);
          }
        } else if (data is Map && data['message']?.contains('Unauthorized') == true) {
          _logout(showLoginMessage: true);
        } else {
          print('PROFILE_SCREEN: Error dari server: $data');
        }
      }
    } on DioException catch (e) {
      print('PROFILE_SCREEN: Error jaringan: $e');
      if (e.response?.statusCode == 401 && mounted) {
        _logout(showLoginMessage: true);
      }
    }
  }

  // Fungsi untuk memilih gambar langsung dari galeri
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          _isLoading = true;
        });
        
        // Check file size (max 20MB)
        final fileSize = await pickedFile.length();
        if (fileSize > 20 * 1024 * 1024) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ukuran file terlalu besar. Maksimal 20MB'),
                backgroundColor: Color(0xFF1F212F),
              ),
            );
          }
          return;
        }
        
        // Untuk web, gunakan bytes
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          await _uploadProfilePictureWeb(bytes, pickedFile.name);
        } else {
          // Untuk mobile, gunakan file
          _imageFile = File(pickedFile.path);
          setState(() {
            _profileImageUrl = null;
          });
          await _uploadProfilePicture(_imageFile!);
        }
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: ${e.toString()}'),
            backgroundColor: Color(0xFF1F212F),
          ),
        );
      }
    }
  }

  // Fungsi untuk mengunggah gambar profil dari web
Future<bool> _isImageAccessible(String url) async {
  try {
    final dio = ApiClient.instance.dio;
    final response = await dio.head(url);
    print("🔍 URL Check: $url - Status: ${response.statusCode}");
    return response.statusCode == 200;
  } catch (e) {
    print("❌ URL Check Failed: $url - Error: $e");
    return false;
  }
}

// Fungsi untuk mengunggah gambar profil dari web
Future<void> _uploadProfilePictureWeb(List<int> imageBytes, String fileName) async {
  try {
    final dio = ApiClient.instance.dio;
    
    // Set timeout yang lebih panjang untuk upload
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    dio.options.sendTimeout = Duration(seconds: 60);
    
    String cleanFileName = fileName.isNotEmpty ? fileName : 'profile_picture.jpg';
    if (!cleanFileName.toLowerCase().endsWith('.jpg') && 
        !cleanFileName.toLowerCase().endsWith('.jpeg') && 
        !cleanFileName.toLowerCase().endsWith('.png')) {
      cleanFileName = 'profile_picture.jpg';
    }
    
    FormData formData = FormData.fromMap({
      'user_id': _userId,
      if (imageBytes.isNotEmpty)
        'profile_picture': MultipartFile.fromBytes(
          imageBytes,
          filename: cleanFileName,
          contentType: MediaType('image', 'jpeg'),
        ),
    });

    print("PROFILE_SCREEN: Uploading image, size: ${imageBytes.length} bytes");
    
    final response = await dio.post(
      'update_profile.php',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      print("PROFILE_SCREEN: Upload response: ${response.statusCode}");
      print("PROFILE_SCREEN: Upload data: ${response.data}");
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 'success') {
          // ✅ Clear cache sebelum update
          _clearImageCache();
          
          String newImageUrl = data['profile_picture_url'];
          
          // ✅ Debug info dari server
          if (data['debug_info'] != null) {
            print("🔍 Debug info: ${data['debug_info']}");
          }
          
          // ✅ Test URL accessibility
          bool isAccessible = await _isImageAccessible(newImageUrl);
          print("🔍 URL Accessible: $isAccessible");
          
          if (!isAccessible) {
            // ✅ Coba alternatif URL jika tidak bisa diakses
            print("⚠️ Original URL not accessible, trying alternatives...");
            
            // Coba beberapa variasi URL
            List<String> urlVariations = [
              newImageUrl.replaceAll('/lib/', '/'),
              newImageUrl.replaceAll('/lib', ''),
              newImageUrl,
            ];
            
            for (String altUrl in urlVariations) {
              bool altAccessible = await _isImageAccessible(altUrl);
              if (altAccessible) {
                newImageUrl = altUrl;
                print("✅ Found accessible URL: $altUrl");
                break;
              }
            }
          }
          
          setState(() {
            _profileImageUrl = newImageUrl;
            _imageFile = null;
          });
          
          // Simpan URL gambar ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_picture', _profileImageUrl!);
          
          // Force rebuild dengan delay
          await Future.delayed(Duration(milliseconds: 500));
          if (mounted) {
            setState(() {});
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Foto profil berhasil diubah'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Gagal mengupload foto');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  } on DioException catch (e) {
    print("DioException uploading image: ${e.type} - ${e.message}");
    
    String errorMessage = 'Gagal mengupload foto';
    
    if (e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Koneksi timeout. Periksa koneksi internet Anda';
    } else if (e.type == DioExceptionType.sendTimeout) {
      errorMessage = 'Upload timeout. File mungkin terlalu besar';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Server tidak merespons';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'Masalah koneksi jaringan. Periksa internet Anda';
    } else if (e.response?.statusCode == 413) {
      errorMessage = 'File terlalu besar untuk diupload';
    } else if (e.response?.statusCode == 401) {
      errorMessage = 'Sesi berakhir. Silakan login kembali';
      _logout(showLoginMessage: true);
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    print("General error uploading image: $e");
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengupload foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // Fungsi untuk mengunggah gambar profil ke server (mobile)
Future<void> _uploadProfilePicture(File imageFile) async {
  try {
    final dio = ApiClient.instance.dio;

    if (_userId == null || _userId!.isEmpty) {
      throw Exception('User ID tidak tersedia. Silakan login ulang.');
    }
    
    // Set timeout yang lebih panjang untuk upload
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    dio.options.sendTimeout = Duration(seconds: 60);
    
    FormData formData = FormData.fromMap({
      'user_id': _userId,
      'profile_picture': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'profile_picture.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });

    print("📤 PROFILE_SCREEN: Uploading image from mobile");
    
    final response = await dio.post(
      'update_profile.php',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      print("📨 Upload response: ${response.statusCode}");
      print("📨 Upload data: ${response.data}");
    
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 'success') {
          print("✅ === UPLOAD SUCCESS ===");
          print("🔗 New profile_picture_url: ${data['profile_picture_url']}");
          print("🔗 Current _profileImageUrl: $_profileImageUrl");

          // ✅ Clear cache SEBELUM update
          _clearImageCache();
          
          // ✅ Get clean URL dari response (tanpa timestamp duplikat)
          String newImageUrl = data['profile_picture_url'];
          
          // ✅ Pastikan URL clean (hapus existing timestamp jika ada)
          if (newImageUrl.contains('?')) {
            newImageUrl = newImageUrl.split('?')[0];
          }
          
          setState(() {
            _profileImageUrl = newImageUrl; // ✅ Simpan URL clean
            _imageFile = null;
          });

          print("🔗 Final _profileImageUrl: $_profileImageUrl");
          print("✅ === END SUCCESS ===");
          
          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_picture', _profileImageUrl!);
          
          // ✅ Force rebuild setelah delay
          await Future.delayed(Duration(milliseconds: 800));
          if (mounted) {
            setState(() {
              print("🔄 Force rebuild triggered");
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Foto profil berhasil diubah'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Gagal mengupload foto');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  } catch (e) {
    print("❌ Error uploading: $e");
    if (mounted) {
      setState(() {
        _isLoading = false;
        _imageFile = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal mengupload foto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  // Fungsi untuk mengedit profil
  void _editProfile() async {
    if (_userName == "Loading..." || _userName == "User") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data profil belum selesai dimuat'))
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(currentName: _userName),
      ),
    );

    // Refresh data setelah kembali dari edit profile
    if (result != null && mounted) {
      _loadUserData();
    }
  }

  // Dialog konfirmasi logout
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1F212F),
          title: Text('Konfirmasi Logout', style: TextStyle(color: Colors.white)),
          content: Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: Text('Batal', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _logout(showLoginMessage: false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout({bool showLoginMessage = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    try {
      final dio = ApiClient.instance.dio;
      final response = await dio.post('logout.php');

      print("Response Status Code: ${response.statusCode}");
      print("Response Data: ${response.data}");

      if (response.statusCode == 200) {
        if (response.data is Map) {
          String status = response.data['status']?.toString() ?? '';
          
          if (status == 'success') {
            await _clearLocalDataSafely(prefs);

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logout berhasil'),
                backgroundColor: Colors.green,
              ),
            );

            if (showLoginMessage) {
              Future.delayed(Duration(milliseconds: 300), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sesi telah berakhir. Silakan login kembali.')),
                  );
                }
              });
            }
          } else {
            String errorMessage = response.data['message']?.toString() ?? 'Logout gagal';
            print('Logout failed: $errorMessage');
            
            await _clearLocalDataSafely(prefs);
            
            if (!mounted) return;
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          print('Unexpected response format: ${response.data}');
          await _clearLocalDataSafely(prefs);
          
          if (!mounted) return;
          
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        print('Server error: ${response.statusCode}');
        await _clearLocalDataSafely(prefs);
        
        if (!mounted) return;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      await _clearLocalDataSafely(prefs);
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout berhasil! Silahkan Login Kembali.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1F212F),
        ),
      );
    }
  }

  Future<void> _clearLocalDataSafely(SharedPreferences prefs) async {
    try {
      await prefs.clear();
      print('SharedPreferences cleared successfully');
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
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
              leading: Icon(Icons.help_outline, color: Color(0xFFA28D4F)),
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
            child: Text("OK", style: TextStyle(color: Color(0xFFA28D4F))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
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
                  trailing: _selectedLanguage == languages[index] 
                    ? Icon(Icons.check, color: Color(0xFFA28D4F))
                    : null,
                  onTap: () {
                    Navigator.pop(context, languages[index]);
                  },
                );
              }
            )
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Color(0xFFA28D4F))),
              onPressed: () => Navigator.pop(context, null)
            )
          ]
        );
      },
    );

    if (selected != null && mounted && selected != _selectedLanguage) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = selected;
      });
      await prefs.setString('language', _selectedLanguage);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bahasa berhasil diubah ke $selected'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("PROFILE_SCREEN: build() dipanggil. UserName: $_userName, ProfileImageUrl: $_profileImageUrl");
    
     return Scaffold(
    backgroundColor: const Color(0xFF0F111D),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0F111D),
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
    ),
    body: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // **PERBAIKAN: Custom Widget untuk Profile Picture**
                  Center(
                    child: Stack(
                      children: [
                        _buildProfileAvatar(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _pickImageFromGallery,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Color(0xFFA28D4F),
                              child: Icon(
                                _isLoading ? Icons.hourglass_empty : Icons.photo_library, 
                                size: 18, 
                                color: Colors.white
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                    
                    // User Info
                    Text(
                      _userName,
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    if (_userEmail.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        _userEmail,
                        style: TextStyle(color: Colors.grey, fontSize: 14)
                      ),
                    ],
                    const SizedBox(height: 30),
                    
                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.person,
                      title: "Edit Profile",
                      onTap: _editProfile,
                    ),
                    const Divider(color: Colors.grey),
                    
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: "Help Center",
                      onTap: _openHelpCenter,
                    ),
                    const Divider(color: Colors.grey),
                    
                    _buildMenuItem(
                      icon: Icons.language,
                      title: "Languages: $_selectedLanguage",
                      onTap: _selectLanguage,
                    ),
                    const Divider(color: Colors.grey),
                    
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: _showLogoutDialog,
                      iconColor: Colors.red,
                      textColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          currentIndex: 3,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
            } else if (index == 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CatalogScreen()));
            } else if (index == 2) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyBooksScreen()));
            }
            // index 3 adalah current page (Profile)
          },
          items: [
            BottomNavigationBarItem(icon: Image.asset('assets/logo.png', width: 30), label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.menu_book, size: 30), label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.bookmark_border, size: 30), label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 30), label: ''),
          ],
        ),
      ),
    );
  }

Widget _buildMenuItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  Color? iconColor,
  Color? textColor,
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: iconColor ?? Color(0xFFA28D4F),
      size: 24,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: textColor ?? Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: Icon(
      Icons.arrow_forward_ios,
      color: Colors.grey,
      size: 16,
    ),
    onTap: onTap,
    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
  );
}
Widget _buildProfileAvatar() {
  // Gunakan timestamp sebagai key untuk force rebuild
  final uniqueKey = ValueKey('${_profileImageUrl}_${DateTime.now().millisecondsSinceEpoch}');
  
  return Container(
    key: uniqueKey,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Color(0xFFA28D4F).withOpacity(0.3),
        width: 2,
      ),
    ),
    child: ClipOval(
      child: Container(
        width: 100,
        height: 100,
        child: _isLoading 
          ? Container(
              color: Colors.grey[800],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28D4F)),
                ),
              ),
            )
          : _buildImage(),
      ),
    ),
  );
}

// Tambahkan fungsi untuk clear image cache:

void _clearImageCache() {
  try {
    // ✅ Clear semua image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    
    // ✅ Clear specific URLs
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      // Clear original URL
      NetworkImage(_profileImageUrl!).evict();
      
      // Clear URL with any possible timestamp variations
      String baseUrl = _profileImageUrl!.split('?')[0];
      NetworkImage(baseUrl).evict();
      
      print("🧹 Cache cleared for: $baseUrl");
    }
    
    print("✅ Image cache cleared successfully");
  } catch (e) {
    print("❌ Error clearing cache: $e");
  }
}

Widget _buildFallbackAvatar() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A2D3A),
          Color(0xFF1F212F),
        ],
      ),
    ),
    child: Icon(
      Icons.person,
      size: 50,
      color: Color(0xFFA28D4F),
    ),
  );
}

Widget _buildImage() {
  // Untuk file lokal (mobile)
  if (_imageFile != null && !kIsWeb) {
    return Image.file(
      _imageFile!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print("❌ Error loading local file: $error");
        return _buildFallbackAvatar();
      },
    );
  }

 
if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
    // ✅ Gunakan URL langsung tanpa tambahan timestamp yang berlebihan
    String imageUrl = _profileImageUrl!;
    
     if (!imageUrl.contains('?')) {
      imageUrl += '?t=${DateTime.now().millisecondsSinceEpoch}';
    }

     print("🔗 Final image URL: $imageUrl");
    
    return Image.network(
      imageUrl,
      key: ValueKey('profile_$imageUrl'),
      fit: BoxFit.cover,
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; LibraReads App)',
        'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
        'Cache-Control': 'no-cache',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[800],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28D4F)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print("❌ Image Error: $error");
        print("🔗 Failed URL: $imageUrl");
        
        // ✅ Coba URL alternatif
        String fallbackUrl = imageUrl.split('?')[0]; // Hapus query params
        
        // Coba beberapa variasi URL
        List<String> urlAttempts = [
          fallbackUrl,
          fallbackUrl.replaceAll('/lib/', '/'),
          fallbackUrl.replaceAll('/lib', ''),
        ];
        
        // Coba URL pertama yang berbeda
        for (String attemptUrl in urlAttempts) {
          if (attemptUrl != imageUrl) {
            print("🔄 Trying fallback URL: $attemptUrl");
            return Image.network(
              attemptUrl,
              key: ValueKey('fallback_$attemptUrl'),
              fit: BoxFit.cover,
              headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; LibraReads App)',
                'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
              },
              errorBuilder: (context, fallbackError, fallbackStack) {
                print("❌ Fallback also failed: $fallbackError");
                return _buildFallbackAvatar();
              },
            );
          }
        }
        
        return _buildFallbackAvatar();
      },
    );
  }
  
  return _buildFallbackAvatar();
}

Widget _buildWebImage(String imageUrl) {
  return Image.network(
    imageUrl,
    key: ValueKey('web_$imageUrl'),
    fit: BoxFit.cover,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        color: Colors.grey[800],
        child: Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28D4F)),
          ),
        ),
      );
    },
      errorBuilder: (context, error, stackTrace) {
      print("❌ Web Image Error: $error");
      print("🔗 Failed URL: $imageUrl");
      
      // ✅ Fallback: coba tanpa timestamp
      String fallbackUrl = imageUrl.split('?')[0];
      return Image.network(
        fallbackUrl,
        key: ValueKey('fallback_$fallbackUrl'),
        fit: BoxFit.cover,
        errorBuilder: (context, fallbackError, fallbackStack) {
          print("❌ Fallback Image Also Failed: $fallbackError");
          return _buildFallbackAvatar();
        },
      );
    },
  );
}

Widget _buildMobileImage(String imageUrl) {
  return Image.network(
    imageUrl,
    key: ValueKey('mobile_$imageUrl'),
    fit: BoxFit.cover,
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; LibraReads Mobile App)',
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    },
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Container(
        color: Colors.grey[800],
        child: Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28D4F)),
          ),
        ),
      );
    },
    errorBuilder: (context, error, stackTrace) {
      print("❌ Mobile Image Error: $error");
      print("🔗 Failed URL: $imageUrl");
      return _buildFallbackAvatar();
    },
  );
}
}
