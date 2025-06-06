import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  final String _apiBaseUrl = "http://192.168.100.22:8080/librareadsmob/lib/";

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: Duration(seconds: 15), // Timeout untuk koneksi
      receiveTimeout: Duration(seconds: 10),
      sendTimeout: Duration(seconds: 10), // Timeout untuk menerima data
      headers: {
        'Accept': 'application/json',
      },
    ));
  }

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  late Dio _dio;
  late PersistCookieJar _cookieJar;

  // Getter untuk memberikan akses ke instance Dio yang sudah dikonfigurasi.
  Dio get dio => _dio;
  PersistCookieJar get cookieJar => _cookieJar;

  /// Fungsi inisialisasi ini HARUS dipanggil sekali saat aplikasi pertama kali berjalan.
  Future<void> initialize() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    _cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(appDocPath + "/.cookies/"),
    );

    _dio.interceptors.add(CookieManager(_cookieJar));

    print("==============================================");
    print("ApiClient dan CookieJar berhasil diinisialisasi.");
    print("Base URL diatur ke: $_apiBaseUrl");
    print("Lokasi penyimpanan cookie: $appDocPath/.cookies/");
    print("==============================================");
  }
}