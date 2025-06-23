import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'api_client.dart';
import 'profile.dart';
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String? currentEmail;
  final String userId;
  final String currentAvatarNumber;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    this.currentEmail,
    required this.userId,
    required this.currentAvatarNumber,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late String _selectedAvatarNumber;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
    _emailController.text = widget.currentEmail ?? '';
    _selectedAvatarNumber = widget.currentAvatarNumber;
    debugPrint("EditProfileScreen: Initial avatar number: $_selectedAvatarNumber");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _getAvatarAssetPath(String avatarNumber) {
    if (avatarNumber.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(avatarNumber)) {
      debugPrint('Invalid avatar number (EditProfile): "$avatarNumber". Falling back to default "1".');
      return 'assets/avatars/1.svg';
    }
    return 'assets/avatars/$avatarNumber.svg';
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.userId.isEmpty) {
      debugPrint("EDIT_PROFILE: User ID from widget is empty, cannot proceed with update.");
      if (mounted) {
        _showSnackBar('Invalid user session. Please log in again.', isError: true);
      }
      await ApiClient.instance.logoutUser(message: 'Invalid user session. Please log in again.');
      return;
    }

    final String newName = _nameController.text.trim();
    final String newEmail = _emailController.text.trim();
    String? nameToUpdate = (newName != widget.currentName) ? newName : null;
    String? emailToUpdate = (newEmail != widget.currentEmail) ? newEmail : null;
    String? avatarToUpdate = (_selectedAvatarNumber != widget.currentAvatarNumber) ? _selectedAvatarNumber : null;

    if (nameToUpdate == null && emailToUpdate == null && avatarToUpdate == null) {
      if (mounted) {
        _showSnackBar('No changes detected to save.');
        Navigator.pop(context, true);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint('EDIT_PROFILE: Sending update profile request for user ID: ${widget.userId}');
      debugPrint('EDIT_PROFILE: Changes: Username: $nameToUpdate, Email: $emailToUpdate, Avatar: $avatarToUpdate');

      final Map<String, dynamic> responseData = await ApiClient.instance.updateProfile(
        userId: widget.userId,
        username: nameToUpdate,
        email: emailToUpdate,
        profilePictureNumber: avatarToUpdate,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        debugPrint('EDIT_PROFILE: Raw response data from updateProfile: $responseData');

        if (responseData['success'] == true) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          if (responseData.containsKey('data')) {
            final Map<String, dynamic> data = responseData['data'];
            if (data.containsKey('username') && data['username'] != null) {
              await prefs.setString('username', data['username']);
              debugPrint("EDIT_PROFILE: SharedPreferences updated for username: ${data['username']}");
            }
            if (data.containsKey('email') && data['email'] != null) {
              await prefs.setString('email', data['email']);
              debugPrint("EDIT_PROFILE: SharedPreferences updated for email: ${data['email']}");
            }
            if (data.containsKey('profile_picture_url') && data['profile_picture_url'] != null) {
              await prefs.setString('selected_avatar_number', data['profile_picture_url'].toString());
              debugPrint("EDIT_PROFILE: SharedPreferences updated for avatar: ${data['profile_picture_url']}");
            }
          }

          _showSnackBar(responseData['message'] ?? 'Profile updated successfully!', isError: false);
          Navigator.pop(context, true);
        } else {
          String message = responseData['message'] ?? 'Failed to update profile. Unknown server message.';
          _showSnackBar(message, isError: true);
        }
      }
    } on DioException catch (e) {
      debugPrint('EDIT_PROFILE: Dio error: ${e.type} - ${e.message}');
      debugPrint('EDIT_PROFILE: Dio response data: ${e.response?.data}');
      debugPrint('EDIT_PROFILE: Dio response status: ${e.response?.statusCode}');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMessage = 'Failed to update profile. Network error.';

        if (e.response != null) {
          if (e.response!.data is Map && e.response!.data.containsKey('message')) {
            errorMessage = e.response!.data['message'].toString();
          } else {
            errorMessage = 'Server response error: ${e.response!.statusCode ?? 'Unknown'}';
          }

          if (e.response!.statusCode == 401) {
            errorMessage = 'Your session has expired. Please log in again.';
            await ApiClient.instance.logoutUser(message: errorMessage);
            return;
          }
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          errorMessage = 'Cannot connect to server. Please check your internet connection.';
        }

        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      debugPrint('EDIT_PROFILE: General error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('An unexpected error occurred: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> avatarNumbers = List.generate(10, (index) => (index + 1).toString());

    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Montserrat',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return ProfileAvatarSelection(
                        avatarNumbers: avatarNumbers,
                        currentSelectedAvatarNumber: _selectedAvatarNumber,
                        onAvatarSelected: (selectedNumber) {
                          setState(() {
                            _selectedAvatarNumber = selectedNumber;
                          });
                          debugPrint("EditProfileScreen: Selected new avatar number: $selectedNumber");
                        },
                      );
                    },
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFA28D4F), width: 3),
                      ),
                      child: ClipOval(
                        child: SvgPicture.asset(
                          _getAvatarAssetPath(_selectedAvatarNumber),
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          placeholderBuilder: (BuildContext context) => Container(
                            padding: const EdgeInsets.all(30.0),
                            child: const CircularProgressIndicator(color: Color(0xFFA28D4F)),
                          ),
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('Error loading SVG avatar in EditProfile: ${_getAvatarAssetPath(_selectedAvatarNumber)}, Error: $error');
                            return SvgPicture.asset(
                              _getAvatarAssetPath('1'),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA28D4F),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.grey, fontFamily: 'Montserrat'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFA28D4F)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1F212F),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.grey, fontFamily: 'Montserrat'),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFA28D4F)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1F212F),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email cannot be empty';
                  }
                  if (!isValidEmail(value.trim())) {
                    return 'Invalid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFA28D4F))
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA28D4F),
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Montserrat'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}