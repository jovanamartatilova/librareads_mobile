// lib/api_client.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  // =================================================================
  // ** PENTING! GANTI URL DI BAWAH INI **
  // Ganti dengan URL ke folder tempat Anda menyimpan file-file PHP.
  // - Gunakan 'http://10.0.2.2/' jika Anda menggunakan Emulator Android.
  // - Gunakan alamat IP lokal Anda (misal: 'http://192.168.x.x/') jika menggunakan HP fisik.
  // =================================================================
  final String _apiBaseUrl = "http://192.168.214.226/librareads/lib";

  // --- Singleton Pattern Setup ---
  // Membuat constructor privat agar tidak bisa diinstansiasi dari luar.
  ApiClient._internal() {
    // Inisialisasi Dio dengan opsi dasar.
    _dio = Dio(BaseOptions(
      baseUrl: _apiBaseUrl, // Mengatur base URL untuk semua request.
      connectTimeout: Duration(milliseconds: 10000), // Timeout koneksi 10 detik
      receiveTimeout: Duration(milliseconds: 5000), // Timeout menerima data 5 detik
    ));
  }

  // Satu-satunya instance dari class ini.
  static final ApiClient _instance = ApiClient._internal();

  // Getter untuk mengakses instance tunggal ini dari mana saja di aplikasi.
  static ApiClient get instance => _instance;
  // --- Akhir dari Singleton Pattern Setup ---

  late Dio _dio;
  late PersistCookieJar _cookieJar;

  // Getter untuk memberikan akses ke instance Dio yang sudah dikonfigurasi.
  Dio get dio => _dio;
  // Getter untuk cookie jar, berguna jika Anda perlu membersihkan cookie saat logout.
  PersistCookieJar get cookieJar => _cookieJar;

  /// Fungsi inisialisasi ini HARUS dipanggil sekali saat aplikasi pertama kali berjalan.
  /// Tempat terbaik untuk memanggilnya adalah di dalam fungsi `main()` di file `main.dart`.
  Future<void> initialize() async {
    // Menyiapkan CookieJar untuk menyimpan session secara persisten di penyimpanan perangkat.
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    _cookieJar = PersistCookieJar(
      ignoreExpires: true, // Terus simpan cookie meskipun sudah kedaluwarsa
      storage: FileStorage(appDocPath + "/.cookies/"),
    );

    // Menambahkan CookieManager ke dalam 'interceptors' Dio.
    // Ini akan secara otomatis menangani pengiriman dan penyimpanan cookie untuk setiap request.
    _dio.interceptors.add(CookieManager(_cookieJar));

    print("==============================================");
    print("ApiClient dan CookieJar berhasil diinisialisasi.");
    print("Base URL: $_apiBaseUrl");
    print("Cookie storage path: $appDocPath/.cookies/");
    print("==============================================");
  }
}