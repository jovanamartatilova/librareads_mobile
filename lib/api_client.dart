import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'auth_interceptor.dart';
import 'login.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  Dio? _dio;
  Dio? _publicDio;
  bool _isInitialized = false;

  final String _apiBaseUrl = "http://192.168.100.22:8080/librareadsmob/lib/";
  String get baseUrl => _apiBaseUrl;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  Dio get dio {
    if (!_isInitialized || _dio == null) {
      log("ApiClient Error: Authenticated Dio not initialized. Call initClient() first.");
      throw StateError(
          "Authenticated ApiClient is not initialized. Call await ApiClient.instance.initClient() first.");
    }
    return _dio!;
  }

  Dio get publicDio {
    if (!_isInitialized || _publicDio == null) {
      log("ApiClient Error: Public Dio not initialized. Call initClient() first.");
      throw StateError(
          "Public ApiClient is not initialized. Call await ApiClient.instance.initClient() first.");
    }
    return _publicDio!;
  }

  Future<void> initClient() async {
    if (_isInitialized && _dio != null && _publicDio != null) {
      log("ApiClient: Client already initialized. Skipping re-initialization.");
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    _publicDio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    log("ApiClient: ✅ Created separate Dio instances");
    log("ApiClient: Platform detection - kIsWeb: $kIsWeb");

    if (!kIsWeb) {
      try {
        _dio!.interceptors.add(CookieManager(CookieJar()));
        _publicDio!.interceptors.add(CookieManager(CookieJar()));
        log("ApiClient: ✅ CookieManager added to both instances (mobile/desktop)");
      } catch (e) {
        log("ApiClient: ❌ CookieManager failed: $e");
      }
    } else {
      log("ApiClient: ⚠️ Skipping CookieManager for web platform");
    }

    _dio!.interceptors.add(AuthInterceptor(this));
    log("ApiClient: ✅ AuthInterceptor added ONLY to authenticated Dio");

    if (kDebugMode) {
      _dio!.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
      ));
      _publicDio!.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: true,
      ));
      log("ApiClient: ✅ LogInterceptor added to both instances");
    }

    log("ApiClient: ===================");
    log("ApiClient: 🔒 Authenticated Dio interceptors: ${_dio!.interceptors.length}");
    for (int i = 0; i < _dio!.interceptors.length; i++) {
      log("ApiClient: 🔒   [$i] ${_dio!.interceptors[i].runtimeType}");
    }
    log("ApiClient: 🌐 Public Dio interceptors: ${_publicDio!.interceptors.length}");
    for (int i = 0; i < _publicDio!.interceptors.length; i++) {
      log("ApiClient: 🌐   [$i] ${_publicDio!.interceptors[i].runtimeType}");
    }
    log("ApiClient: ===================");

    _isInitialized = true;
    log("ApiClient: ✅ Initialization complete with base URL: $_apiBaseUrl");
  }

  Future<void> setAuthToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (token.isNotEmpty) {
      await prefs.setString('auth_token', token);
      log('ApiClient: Auth token saved to SharedPreferences.');
    } else {
      await prefs.remove('auth_token');
      log('ApiClient: Attempted to set empty token. Token removed from SharedPreferences.');
    }
  }

  Future<String?> loadAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      log('ApiClient: Auth token loaded from SharedPreferences on startup (for info).');
      return token;
    } else {
      log('ApiClient: No auth token found in SharedPreferences on startup.');
      return null;
    }
  }

  Future<Map<String, dynamic>> loginUser({required String username, required String password}) async {
    try {
      log("ApiClient: ========== LOGIN DEBUG START ==========");
      log("ApiClient: Username: $username");
      log("ApiClient: Using publicDio for login (should be token-free)");

      if (!_isInitialized || _publicDio == null) {
        await initClient();
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? existingToken = prefs.getString('auth_token');
      log("ApiClient: Existing token check: ${existingToken != null ? 'Token exists' : 'No token'}");

      final Map<String, dynamic> dataPayload = {
        'username': username,
        'password': password,
      };

      log("ApiClient: 📤 Sending login request to: /login.php");
      log("ApiClient: 📤 Data payload for username: $username");

      final response = await _publicDio!.post(
        '/login.php',
        data: dataPayload,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      log("ApiClient: 📥 Response received - Status: ${response.statusCode}");
      log("ApiClient: 📥 Response data: ${response.data}");
      log("ApiClient: ========== LOGIN DEBUG END ==========");

      if (response.statusCode == 200 && response.data is Map<String, dynamic> && response.data['status'] == 'success') {
        final String token = response.data['token'] ?? response.data['auth_token'] ?? '';
        final String? userId = response.data['user_id']?.toString();
        final String? responseUsername = response.data['username'];
        final String? email = response.data['email'];
        final String? avatarNumber = response.data['profile_picture_url']?.toString();

        if (token.isNotEmpty) {
          await prefs.setString('auth_token', token);
          log("ApiClient: ✅ Auth token saved: $token");
        } else {
          log("ApiClient: ⚠️ No token found in login response.");
          await prefs.remove('auth_token');
        }

        if (userId != null && userId.isNotEmpty) {
          await prefs.setString('user_id', userId);
          log("ApiClient: ✅ Login successful - User ID saved: $userId");
        } else {
          log("ApiClient: ⚠️ User ID not found in login response or was empty. This might cause issues.");
          await prefs.remove('user_id');
        }
        
        if (responseUsername != null) await prefs.setString('username', responseUsername);
        if (email != null) await prefs.setString('email', email);

        String finalAvatarNumber = '1';
        if (avatarNumber != null && avatarNumber.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(avatarNumber)) {
          finalAvatarNumber = avatarNumber;
        } else {
          log("ApiClient: ⚠️ Invalid or empty avatar number from login response. Defaulting to '1'. Original: '$avatarNumber'");
        }
        await prefs.setString('selected_avatar_number', finalAvatarNumber);
        log("ApiClient: ✅ Final avatar number saved: $finalAvatarNumber");

        await prefs.setBool('logged_in', true);
        log("ApiClient: ✅ Login successful and data saved to SharedPreferences");
        
        return {
          'status': 'success',
          'message': response.data['message'],
          'user_id': userId,
          'username': responseUsername,
          'email': email,
          'profile_picture_url': finalAvatarNumber,
        };
      } else {
        String errorMessage = response.data?['message'] ?? 'Login failed - invalid credentials or server error';
        log("ApiClient: ❌ Login failed: $errorMessage");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }
    } on DioException catch (e) {
      log("ApiClient: ❌ DioError in loginUser: ${e.response?.data ?? e.message}");
      log("ApiClient: ❌ Status Code: ${e.response?.statusCode}");
      log("ApiClient: ❌ Request headers: ${e.requestOptions.headers}");
      rethrow;
    } catch (e) {
      log("ApiClient: ❌ Unexpected error in loginUser: $e");
      throw Exception('Unexpected error during login: $e');
    }
  }
  Future<Map<String, dynamic>> registerUser({required String username, required String password, String? email}) async {
    try {
      if (!_isInitialized || _publicDio == null) {
        await initClient();
      }
      log("ApiClient: Sending registration request to: /register.php for username: $username");
      final response = await _publicDio!.post(
        '/register.php',
        data: {
          'username': username,
          'password': password,
          'email': email,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      log("ApiClient: Registration response received: ${response.data}");
      return response.data;
    } on DioException catch (e) {
      log('ApiClient: Dio register error: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e) {
      log('ApiClient: General register error: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getProfile({required String userId}) async {
    try {
      if (!_isInitialized || _dio == null) {
        await initClient(); // Ensure client is initialized before making a request
        if (!_isInitialized || _dio == null) { // Check again after attempting init
          throw StateError("ApiClient not initialized even after attempting initClient().");
        }
      }
      if (userId.isEmpty) {
        log('ApiClient: Error: User ID cannot be empty for getProfile call.');
        throw Exception('User ID cannot be empty for getProfile call.');
      }
      log("ApiClient: Getting profile for user ID: $userId from /get_profile.php");

      final response = await dio.get('/get_profile.php', queryParameters: {'user_id': userId});

      log("ApiClient: Get Profile response status: ${response.statusCode}");
      log("ApiClient: Get Profile response data: ${response.data}");

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        if (response.data['status'] == 'success') {
          log("ApiClient: Get Profile success. Updating local SharedPreferences.");

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          
          if (response.data.containsKey('username') && response.data['username'] != null) {
            await prefs.setString('username', response.data['username']);
            log("ApiClient: Username updated from getProfile: ${response.data['username']}");
          } else {
            log("ApiClient: ⚠️ Username missing or null in getProfile response.");
          }

          if (response.data.containsKey('email') && response.data['email'] != null) {
            await prefs.setString('email', response.data['email']);
            log("ApiClient: Email updated from getProfile: ${response.data['email']}");
          } else {
            log("ApiClient: ⚠️ Email missing or null in getProfile response.");
          }

          final String? avatarNumber = response.data['profile_picture_url']?.toString();
          String finalAvatarNumber = '1';
          if (avatarNumber != null && avatarNumber.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(avatarNumber)) {
            finalAvatarNumber = avatarNumber;
          } else {
            log("ApiClient: ⚠️ Invalid or empty avatar number from getProfile response. Defaulting to '1'. Original: '$avatarNumber'");
          }
          await prefs.setString('selected_avatar_number', finalAvatarNumber);
          log("ApiClient: ✅ Profile picture (avatar number) updated in SharedPreferences from getProfile response: $finalAvatarNumber.");

          return response.data;
        } else {
          log("ApiClient: Get Profile API returned non-success status: ${response.data['status']} - Message: ${response.data['message']}");
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            error: response.data['message'] ?? 'Gagal mengambil data profil (API message kosong).',
          );
        }
      } else {
        log("ApiClient: Get Profile received non-200 status or invalid data type. Status: ${response.statusCode}, Data: ${response.data.runtimeType}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Server error: ${response.statusCode} or unexpected response format.',
        );
      }
    } on DioException catch (e) {
      log("ApiClient: DioError in getProfile: ${e.response?.data ?? e.message}");
      rethrow;
    } catch (e) {
      log("ApiClient: Unexpected error in getProfile: $e");
      throw Exception('Terjadi kesalahan tidak terduga saat mengambil profil: $e');
    }
  }

  Future<void> logoutUser({String? message}) async {
    log("ApiClient: Performing application-wide logout.");

    try {
      if (_isInitialized && _dio != null) {
        final response = await dio.post('/logout.php');
        if (response.statusCode == 200 && response.data is Map<String, dynamic> && response.data['status'] == 'success') {
          log('ApiClient: API Logout successful: ${response.data['message']}');
        } else {
          log('ApiClient: API Logout failed (status code ${response.statusCode}): ${response.data['message'] ?? 'No message'}.');
        }
      } else {
        log("ApiClient: Authenticated Dio is not initialized, skipping API logout call.");
      }
    } on DioException catch (e) {
      log("ApiClient: Error during logout API call: ${e.response?.data ?? e.message}");
    } catch (e) {
      log("ApiClient: Unexpected error during logout API call: $e");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('email');
    await prefs.remove('auth_token');
    await prefs.setBool('logged_in', false);
    await prefs.remove('selected_avatar_number');
    log("ApiClient: All authentication data cleared locally, 'selected_avatar_number' removed.");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? currentContext = navigatorKey.currentState?.context;
      if (currentContext != null && navigatorKey.currentState!.mounted) {
        if (message != null) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          log("ApiClient: Showing SnackBar: $message");
        }

        log("ApiClient: Navigating to LoginPage via GlobalKey.");
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        log("ApiClient: Warning: navigatorKey.currentState is not available or mounted. Cannot show snackbar or navigate to login page.");
      }
    });
  }

  static ApiClient get instance {
    return _instance;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    String? username,
    String? email,
    String? profilePictureNumber,
  }) async {
    try {
      if (!_isInitialized || _dio == null) {
        await initClient();
        if (!_isInitialized || _dio == null) {
          throw StateError("ApiClient not initialized even after attempting initClient().");
        }
      }
      if (userId.isEmpty) {
        log('ApiClient: Error: User ID cannot be empty for profile update.');
        throw Exception('User ID cannot be empty for profile update.');
      }
      log("ApiClient: Attempting to update profile for user ID: $userId");

      Map<String, dynamic> dataPayload = {'user_id': userId};
      if (username != null) dataPayload['username'] = username;
      if (email != null) dataPayload['email'] = email;
      if (profilePictureNumber != null) dataPayload['profile_picture_url'] = profilePictureNumber;

      log("ApiClient: Update Profile Payload: $dataPayload");

      final response = await dio.post(
        '/update_profile.php',
        data: dataPayload,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      log("ApiClient: Update Profile response status: ${response.statusCode}");
      log("ApiClient: Update Profile response data: ${response.data}");

      if (response.statusCode == 200 && response.data is Map<String, dynamic> && response.data['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        final Map<String, dynamic>? updatedUserData = response.data['data'];

        if (updatedUserData != null) {
          String finalAvatarNumber = '1';
          if (updatedUserData.containsKey('profile_picture_url') && updatedUserData['profile_picture_url'] != null) {
            String receivedAvatarNumber = updatedUserData['profile_picture_url'].toString();
            if (receivedAvatarNumber.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(receivedAvatarNumber)) {
              finalAvatarNumber = receivedAvatarNumber;
            } else {
              log("ApiClient: ⚠️ Invalid or empty avatar number from updateProfile response ('data' key). Defaulting to '1'. Original: '$receivedAvatarNumber'");
            }
          } else {
            log("ApiClient: ⚠️ 'profile_picture_url' key missing or null in updateProfile response ('data' key). Defaulting to '1'.");
          }
          await prefs.setString('selected_avatar_number', finalAvatarNumber);
          log("ApiClient: ✅ Profile picture (avatar number) updated in SharedPreferences from updateProfile response ('data' key): $finalAvatarNumber.");

          if (updatedUserData.containsKey('username') && updatedUserData['username'] != null) await prefs.setString('username', updatedUserData['username']);
          if (updatedUserData.containsKey('email') && updatedUserData['email'] != null) await prefs.setString('email', updatedUserData['email']);
          
          log("ApiClient: Profile updated and local data refreshed from API response 'data' key.");
        } else {
            if (username != null) {
                await prefs.setString('username', username);
                log("ApiClient: Username updated in SharedPreferences (fallback from sent data).");
            }
            if (email != null) {
                await prefs.setString('email', email);
                log("ApiClient: Email updated in SharedPreferences (fallback from sent data).");
            }
            if (profilePictureNumber != null) {
                await prefs.setString('selected_avatar_number', profilePictureNumber);
                log("ApiClient: Avatar number updated in SharedPreferences (fallback from sent data).");
            }
            log("ApiClient: Profile updated and local data refreshed from sent data (no 'data' key from API).");
        }
        return response.data;
      } else {
        String errorMessage = response.data?['message'] ?? 'Gagal memperbarui profil.';
        log("ApiClient: ❌ Update Profile failed: $errorMessage");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: errorMessage,
        );
      }
    } on DioException catch (e) {
      log("ApiClient: DioError in updateProfile: ${e.response?.data ?? e.message}");
      rethrow;
    } catch (e) {
      log("ApiClient: Unexpected error in updateProfile: $e");
      throw Exception('Terjadi kesalahan tidak terduga saat memperbarui profil: $e');
    }
  }

  Future<List<Book>> getBooks() async {
    try {
      if (!_isInitialized || _publicDio == null) {
        await initClient();
        if (!_isInitialized || _publicDio == null) {
          throw StateError("Public ApiClient is not initialized even after attempting initClient().");
        }
      }
      log("ApiClient: Fetching books from /books.php");
      final response = await _publicDio!.get('books.php');

      log("ApiClient: Books response status: ${response.statusCode}");
      log("ApiClient: Books response data (partial): ${response.data is Map ? (response.data as Map).keys : response.data.runtimeType}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['status'] == 'success' && responseData.containsKey('books')) {
          final List<dynamic> bookListJson = responseData['books'];
          log("ApiClient: Successfully parsed ${bookListJson.length} books.");
          return bookListJson.map((json) => Book.fromJson(json)).toList();
        } else {
          log("ApiClient: Books API returned non-success status or missing 'books' key. Message: ${responseData['message'] ?? 'No message'}");
          throw Exception(responseData['message'] ?? 'Failed to load books: Invalid response format');
        }
      } else {
        log("ApiClient: Failed to load books: Status Code ${response.statusCode}");
        throw Exception('Failed to load books: Status Code ${response.statusCode}');
      }
    } on DioException catch (e) {
      log("ApiClient: DioError fetching books: ${e.response?.data ?? e.message}");
      rethrow;
    } catch (e) {
      log("ApiClient: Unexpected error fetching books: $e");
      rethrow;
    }
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String coverImageUrl;
  final String fileUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImageUrl,
    required this.fileUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'] as String,
      author: json['author'] as String,
      coverImageUrl: json['cover_image_url'] as String,
      fileUrl: json['file_url'] as String,
    );
  }
}