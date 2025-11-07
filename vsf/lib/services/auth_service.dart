// services/supabase_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'dart:math';

// GANTIKAN DENGAN KEYS ASLI ANDA
const String SUPABASE_URL = 'https://jazhzojpgcumghslmquk.supabase.co'; 
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imphemh6b2pwZ2N1bWdoc2xtcXVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTk5MzUsImV4cCI6MjA3NzM3NTkzNX0.uPzc8dVI-LgDXY2aS_K8rSWx7kdwL5oV6xBHS9j1xEo'; 

class SupabaseAuthService {
  
  final String _metadataTableUrl = '$SUPABASE_URL/rest/v1/users'; 
  final _userBoxName = 'users';
  
  final _headers = {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': 'Bearer $SUPABASE_ANON_KEY',
  };

  // ===============================================
  // HELPER PENTING: HASHING (DIPUSATKAN)
  // ===============================================

  /// Fungsi hashing password yang HARUS SAMA PERSIS saat Register dan Login.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Helper: Membuat ID unik lokal
  String _generateLocalUniqueId(UserType type) {
    final prefix = type == UserType.individual ? 'ind' : 'org';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999);
    return '${prefix}_${timestamp}_$random';
  }

  // ===============================================
  // A. REGISTER (Mendaftarkan User ke Hive & Sinkronisasi ID ke Supabase)
  // ===============================================

  Future<String> registerAndSyncId({
    required String email, 
    required UserType userType,
    required String password, // Menerima password mentah
    String? fullName, 
    String? nik,
    String? organizationName,
    String? npwp,
    String? bio, 
    double? latitude, 
    double? longitude, 
    String? profileImagePath, 
  }) async {
    final userBox = Hive.box<UserModel>(_userBoxName);
    
    if (userBox.values.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email sudah terdaftar secara lokal.');
    }
    
    final String localUid = _generateLocalUniqueId(userType);
    final String hashedPassword = SupabaseAuthService.hashPassword(password); // HASH DARI STATIC

    // SINKRONISASI ID & Metadata MINIMAL ke Supabase 
    await _insertUserMetadata(
      uid: localUid, 
      email: email, 
      userType: userType, 
      fullName: fullName, 
      organizationName: organizationName,
      latitude: latitude, 
      longitude: longitude,
    );
    
    // Simpan UserModel LENGKAP ke Hive
    final newUser = UserModel(
      id: localUid,
      email: email,
      passwordHash: hashedPassword, 
      userType: userType,
      fullName: fullName,
      nik: nik,
      organizationName: organizationName,
      npwp: npwp,
      bio: bio, 
      profileImagePath: profileImagePath, 
      latitude: latitude, 
      longitude: longitude,
    );
    
    await userBox.put(localUid, newUser);
    
    return localUid;
  }
  
  /// Memasukkan metadata user minimal ke tabel 'users' di database Supabase
  Future<void> _insertUserMetadata({
    required String uid, 
    required String email, 
    required UserType userType, 
    String? fullName, 
    String? organizationName, 
    double? latitude, 
    double? longitude,
  }) async {
    // Payload dengan NAMA KOLOM DARI SKEMA SUPABASE
    final payload = {
        'id': uid, 
        'email': email,
        'user_type': userType.name,
        'full_name': fullName, 
        'organization_name': organizationName, 
        // Hanya kolom yang ada di tabel Supabase
        'location_latitude': latitude, 
        'location_longitude': longitude,
    };
    
    final response = await http.post(
      Uri.parse(_metadataTableUrl),
      headers: _headers, 
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw Exception('Gagal sinkronisasi ID user ke Supabase: ${response.body}');
    }
    print('✅ Metadata user $uid berhasil disinkronkan ke Supabase.');
  }

  // ===============================================
  // B. SIGN IN (Login) - Menggunakan Otentikasi Lokal (Hive)
  // ===============================================

  /// Login user menggunakan email dan password, diverifikasi secara lokal
  Future<UserModel?> signInUser(String email, String password) async {
    final userBox = Hive.box<UserModel>(_userBoxName);
    
    // 1. Cari user
    final user = userBox.values.cast<UserModel?>().firstWhere(
      (u) => u != null && u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => null,
    );

    if (user == null) {
      throw Exception('Email atau kata sandi salah.'); 
    }
    
    // 2. Hash password yang dimasukkan
    final inputPasswordHash = SupabaseAuthService.hashPassword(password);
    
    // 3. Verifikasi hash
    if (user.passwordHash == inputPasswordHash) {
      return user; 
    } else {
      throw Exception('Email atau kata sandi salah.');
    }
  }

  // ===============================================
  // C. GET CURRENT USER & LOGOUT
  // ===============================================
  
  UserModel? getCurrentUser() {
    final userBox = Hive.box<UserModel>(_userBoxName);
    if (userBox.isNotEmpty) {
      return userBox.values.first;
    }
    return null;
  }

  Future<void> signOut() async {
    print('User berhasil logout.');
  }
}