import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;

  const EditProfileScreen({
    Key? key,
    required this.currentName,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan perubahan username ke server
  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      String newName = _nameController.text.trim();

      try {
        // Ambil token/user_id dari SharedPreferences jika diperlukan
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('user_id');
        String? token = prefs.getString('token');

        // Kirim data ke server untuk memperbarui username
        final dio = ApiClient.instance.dio;
        final response = await dio.post(
          'http://192.168.100.22:8080/librareadsmob/lib/update_profile.php',
          data: {
            'username': newName,
            'user_id': userId, // Tambahkan user_id jika diperlukan
            // 'token': token, // Tambahkan token jika diperlukan
          },
        );

        if (response.statusCode == 200 && response.data['status'] == 'success') {
          // Setelah berhasil mengupdate di server, simpan perubahan ke SharedPreferences
          await prefs.setString('username', newName);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Username berhasil diperbarui!'),
                backgroundColor: Colors.green,
              ),
            );
            // Return data yang telah diupdate ke halaman sebelumnya
            Navigator.pop(context, newName);
          }
        } else {
          if (mounted) {
            String errorMessage = response.data['message'] ?? 'Gagal memperbarui username. Coba lagi.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error updating profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan jaringan, coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        title: const Text('Edit Username', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFA28D4F),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save, color: Color(0xFFA28D4F)),
                  onPressed: _saveProfileChanges,
                )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Color(0xFFA28D4F)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFA28D4F)),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  helperText: "Masukkan username baru Anda.",
                  helperStyle: TextStyle(color: Colors.grey[600]),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username tidak boleh kosong!';
                  }
                  if (value.trim().length < 3) {
                    return 'Username minimal 3 karakter!';
                  }
                  if (value.trim().length > 20) {
                    return 'Username maksimal 20 karakter!';
                  }
                  // Validasi karakter yang diizinkan
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                    return 'Username hanya boleh berisi huruf, angka, dan underscore!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              // Tambahan tombol save untuk kemudahan
              if (!_isLoading)
                ElevatedButton(
                  onPressed: _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA28D4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}