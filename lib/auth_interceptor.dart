import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AuthInterceptor extends Interceptor {
  final ApiClient _apiClient;

  AuthInterceptor(this._apiClient);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('AUTH_INTERCEPTOR: ✅ Token added for ${options.path}');
      } else {
        debugPrint('AUTH_INTERCEPTOR: ⚠️ No token available for ${options.path}');
      }
    } catch (e) {
      debugPrint('AUTH_INTERCEPTOR: ❌ Error getting token: $e');
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('AUTH_INTERCEPTOR: Error ${err.response?.statusCode} for ${err.requestOptions.path}');
    const List<String> publicEndpoints = [
      '/login.php',
      '/register.php',
      '/forgotpassword.php',
      '/logout.php',
    ];

    bool isPublicEndpoint = publicEndpoints.any((endpoint) => 
      err.requestOptions.path.contains(endpoint)
    );

    if (err.response?.statusCode == 401 && !isPublicEndpoint) {
      debugPrint('AUTH_INTERCEPTOR: 🔴 401 on protected endpoint - forcing logout');
      
      try {
        await _apiClient.logoutUser(message: 'Session expired. Please login again.');
      } catch (e) {
        debugPrint('AUTH_INTERCEPTOR: ❌ Error during forced logout: $e');
      }
      return;
    }
    if (err.response?.statusCode == 401 && isPublicEndpoint) {
      debugPrint('AUTH_INTERCEPTOR: ⚠️ Login failed - invalid credentials');
    }
    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('AUTH_INTERCEPTOR: ✅ Response ${response.statusCode} for ${response.requestOptions.path}');
    return handler.next(response);
  }
}