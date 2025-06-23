// lib/profile.dart - REVISED FULL VERSION
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'editprofile.dart';
import 'bottomnavbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Loading...";
  String _userEmail = "";
  String? _userId;
  String _selectedAvatarNumber = '1';

  bool _isProfileLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  String _getAvatarAssetPath(String avatarNumber) {
    return 'assets/avatars/$avatarNumber.svg';
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isProfileLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? localUserId = prefs.getString('user_id');
    String localUsername = prefs.getString('username') ?? "User";
    String localEmail = prefs.getString('email') ?? "";
    String localAvatarNumber = prefs.getString('selected_avatar_number') ?? '1';

    if (mounted) {
      setState(() {
        _userId = localUserId; // Update the state variable
        _userName = localUsername;
        _userEmail = localEmail;
        _selectedAvatarNumber = localAvatarNumber;
      });
    }
    debugPrint("PROFILE_SCREEN: Loaded from SharedPreferences - User ID: $_userId, Username: $_userName, Email: $_userEmail, Avatar: $_selectedAvatarNumber");
    if (_userId == null || _userId!.isEmpty) {
      debugPrint("PROFILE_SCREEN: User ID is null or empty from SharedPreferences. Cannot fetch profile from API. Displaying local data if any.");
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
      return;
    }

    try {
      debugPrint('PROFILE_SCREEN: Attempting to fetch profile from API for user ID: $_userId');
      final Map<String, dynamic> profileData = await ApiClient.instance.getProfile(userId: _userId!);

      debugPrint('PROFILE_SCREEN: Profile data successfully received from server: $profileData');

      if (mounted) {
        setState(() {
          _userName = profileData['username'] ?? _userName;
          _userEmail = profileData['email'] ?? _userEmail;
          String serverAvatarNum = profileData['profile_picture_url']?.toString() ?? '';
          
          if (serverAvatarNum.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(serverAvatarNum)) {
            _selectedAvatarNumber = serverAvatarNum;
            debugPrint("PROFILE_SCREEN: Avatar updated from server: $_selectedAvatarNumber");
          } else {
            _selectedAvatarNumber = prefs.getString('selected_avatar_number') ?? '1';
            debugPrint("PROFILE_SCREEN: ⚠️ Server avatar number invalid. Using local/default: $_selectedAvatarNumber. Server response: '$serverAvatarNum'");
          }
        });
        await prefs.setString('username', _userName);
        await prefs.setString('email', _userEmail);
        await prefs.setString('selected_avatar_number', _selectedAvatarNumber); // Save the final resolved avatar number
        debugPrint('PROFILE_SCREEN: ✅ Profile data and avatar refreshed and saved locally from API.');
      }
    } on DioException catch (e) {
      debugPrint('PROFILE_SCREEN: Network error (DioException): ${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 401 && mounted) {
        debugPrint('PROFILE_SCREEN: DioException 401. Forcing logout.');
        await ApiClient.instance.logoutUser(message: 'Your session has expired. Please log in again.');
      } else {
        String errorMessage = 'Failed to load profile data.'; // Default message
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection issue. Please check your internet connection.';
        } else if (e.response != null && e.response!.data is Map && e.response!.data.containsKey('message') && e.response!.data['message'] != null) {
          errorMessage = e.response!.data['message'];
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('PROFILE_SCREEN: General error loading profile data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred while loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    }
  }

  void _editProfile() async {
    if (_isProfileLoading && _userName == "Loading...") {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile data is still loading. Please wait.')),
        );
      }
      return;
    }

    if (_userId == null || _userId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not available. Please log in again.')),
        );
      }
      debugPrint("PROFILE_SCREEN: Cannot edit profile because User ID is null or empty.");
      return;
    }

    debugPrint("PROFILE_SCREEN: Navigating to EditProfileScreen with:");
    debugPrint("  currentName: $_userName");
    debugPrint("  currentEmail: $_userEmail");
    debugPrint("  currentAvatarNumber: $_selectedAvatarNumber");
    debugPrint("  userId: $_userId");

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: _userName,
          currentEmail: _userEmail,
          currentAvatarNumber: _selectedAvatarNumber,
          userId: _userId!,
        ),
      ),
    );

    if (result == true && mounted) {
      debugPrint("PROFILE_SCREEN: EditProfileScreen returned true, reloading user data.");
      await _loadUserData();
    } else {
      debugPrint("PROFILE_SCREEN: EditProfileScreen returned false or null (no update/cancelled).");
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C47),
          title: const Text('Confirm Logout',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Montserrat',
              )),
          content: const Text(
            'Are you sure you want to log out of the application?',
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'Montserrat',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel',
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Montserrat',
                  )),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Montserrat',
                  )),
              onPressed: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    debugPrint("PROFILE_SCREEN: _logout() function called. Delegating to ApiClient.logoutUser().");
    await ApiClient.instance.logoutUser(message: 'You have successfully logged out.');
  }

  void _openHelpCenter() async {
    const String email = 'librareads@gmail.com';
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Help Request from LibraReads App',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to launch email client. Please send an email to $email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C47),
        title: const Text('Frequently Asked Questions (FAQ)',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Montserrat',
            )),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Q: What is LibraReads?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                'A: LibraReads is a digital library app where you can find, read, and manage your e-books.',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Q: How do I borrow a book?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                'A: You can browse the catalog, select a book, and click the "Read Book" button. The book will then appear in your "My Books" section.',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Q: What if I forget my password?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                'A: You can use the "Forgot Password" option on the login screen to reset your password.',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Q: How do I update my profile information?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                'A: Go to the Profile screen, click "Edit Profile" to change your username or email address.',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Montserrat',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close',
                style: TextStyle(
                  color: Color(0xFFA28D4F),
                  fontFamily: 'Montserrat',
                )),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final List<String> _avatarNumbers = List.generate(10, (index) => (index + 1).toString());

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFA28D4F), width: 3),
      ),
      child: GestureDetector(
        onTap: () {
          if (_userId == null || _userId!.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User ID not available. Cannot change avatar.')),
              );
            }
            return;
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return ProfileAvatarSelection(
                avatarNumbers: _avatarNumbers,
                currentSelectedAvatarNumber: _selectedAvatarNumber,
                onAvatarSelected: (selectedNumber) {
                  setState(() {
                    _selectedAvatarNumber = selectedNumber;
                  });
                  debugPrint("ProfileScreen: Selected new avatar number locally: $selectedNumber");
                  _saveAvatarToBackend(selectedNumber);
                },
              );
            },
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipOval(
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
                  debugPrint('Error loading SVG avatar: ${_getAvatarAssetPath(_selectedAvatarNumber)}, Error: $error');
                  return SvgPicture.asset(
                    _getAvatarAssetPath('1'),
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  );
                },
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
    );
  }

  Future<void> _saveAvatarToBackend(String newAvatarNumber) async {
    if (_userId == null || _userId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not available to save avatar.')),
        );
      }
      debugPrint("PROFILE_SCREEN: Cannot save avatar because User ID is null or empty.");
      return;
    }
    try {
      debugPrint("PROFILE_SCREEN: Attempting to save avatar $newAvatarNumber to backend for user $_userId");
      final response = await ApiClient.instance.updateProfile(
        userId: _userId!,
        profilePictureNumber: newAvatarNumber,
      );
      if (mounted) {
        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
          await _loadUserData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to update avatar.')),
          );
          debugPrint("PROFILE_SCREEN: Failed to save avatar: ${response['message']}");
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to update avatar: Network error.';
      if (e.response?.data != null && e.response!.data is Map && e.response!.data.containsKey('message') && e.response!.data['message'] != null) {
        errorMessage = e.response!.data['message'];
      }
      if (e.response?.statusCode == 401 && mounted) {
        debugPrint('PROFILE_SCREEN: DioException 401 during avatar update. Forcing logout.');
        await ApiClient.instance.logoutUser(message: 'Your session has expired. Please log in again.');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        debugPrint('PROFILE_SCREEN: DioException during avatar update: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred while saving avatar: ${e.toString()}')),
        );
      }
      debugPrint('PROFILE_SCREEN: Unexpected error saving avatar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isProfileLoading && _userName == "Loading..."
       ? const Center(
                   child: CircularProgressIndicator(color: Color(0xFFA28D4F)),
                 )
               : RefreshIndicator(
                   onRefresh: _loadUserData,
                   color: const Color(0xFFA28D4F),
                   backgroundColor: const Color(0xFF2C2C47),
                   child: SingleChildScrollView(
                     physics: const AlwaysScrollableScrollPhysics(),
                     child: Padding(
                       padding: const EdgeInsets.all(20.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.center,
                         children: [
                           _buildProfileAvatar(),
                           const SizedBox(height: 20),
                           Text(
                             _userName,
                             style: const TextStyle(
                               color: Colors.white,
                               fontSize: 24,
                               fontWeight: FontWeight.bold,
                               fontFamily: 'Montserrat',
                             ),
                           ),
                           const SizedBox(height: 5),
                           Text(
                             _userEmail,
                             style: const TextStyle(
                               color: Colors.white70,
                               fontSize: 16,
                               fontFamily: 'Montserrat',
                             ),
                           ),
                           const SizedBox(height: 30),
                           _buildProfileOption(
                             icon: Icons.edit,
                             title: 'Edit Profile',
                             onTap: _editProfile,
                           ),
                           _buildProfileOption(
                             icon: Icons.help_outline,
                             title: 'Help Center',
                             onTap: _openHelpCenter,
                           ),
                           _buildProfileOption(
                             icon: Icons.info_outline,
                             title: 'FAQ',
                             onTap: _openFAQ,
                           ),
                           _buildProfileOption(
                             icon: Icons.logout,
                             title: 'Logout',
                             onTap: _showLogoutDialog,
                             isLogout: true,
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
              
      bottomNavigationBar: const BottomNavBar(
        currentIndex: 3,
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Card(
      color: const Color(0xFF2C2C47),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout ? Colors.redAccent : const Color(0xFFA28D4F),
                size: 26,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isLogout ? Colors.redAccent : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isLogout ? Colors.redAccent : Colors.white54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileAvatarSelection extends StatelessWidget {
  final List<String> avatarNumbers;
  final Function(String) onAvatarSelected;
  final String currentSelectedAvatarNumber;

  const ProfileAvatarSelection({
    Key? key,
    required this.avatarNumbers,
    required this.onAvatarSelected,
    required this.currentSelectedAvatarNumber,
  }) : super(key: key);

  String _getAvatarAssetPath(String avatarNumber) {
    return 'assets/avatars/$avatarNumber.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F111D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pilih Avatar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontFamily: 'Montserrat'),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: avatarNumbers.length,
              itemBuilder: (context, index) {
                String avatarNum = avatarNumbers[index];
                bool isSelected = avatarNum == currentSelectedAvatarNumber;

                return GestureDetector(
                  onTap: () {
                    onAvatarSelected(avatarNum);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFA28D4F).withOpacity(0.5) : const Color(0xFF2C2C47),
                      borderRadius: BorderRadius.circular(8.0),
                      border: isSelected ? Border.all(color: const Color(0xFFA28D4F), width: 3.0) : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SvgPicture.asset(
                        _getAvatarAssetPath(avatarNum),
                        fit: BoxFit.contain,
                        placeholderBuilder: (BuildContext context) => Container(
                          padding: const EdgeInsets.all(8.0),
                          child: const CircularProgressIndicator(color: Color(0xFFA28D4F)),
                        ),
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading SVG avatar: ${_getAvatarAssetPath(avatarNum)}, Error: $error');
                          return const Icon(Icons.broken_image, color: Colors.red);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}