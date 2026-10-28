import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  static final AuthController instance = AuthController._internal();
  AuthController._internal();

  final _supabase = Supabase.instance.client;
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  /// Registrasi akun baru ke Supabase & sinkronisasi ke tabel profiles
  /// Langsung memanggil signOut() agar tidak meninggalkan session yang terkunci
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Simpan fallback kredensial lokal
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      await _storage.write(key: 'reg_username_$email', value: username);
      if (phone != null && phone.isNotEmpty) {
        await _storage.write(key: 'reg_phone_$email', value: phone);
      }
      await _storage.write(key: 'reg_password_$email', value: hashedPassword);
      await _storage.write(key: 'username_to_email_$username', value: email);
      await _storage.write(key: 'last_registered_email', value: email);

      // Pastikan tidak ada session aktif yang mengunci login
      await _storage.delete(key: 'active_email');
      await _storage.delete(key: 'active_username');

      // 2. Registrasi ke Supabase Auth
      try {
        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // Sinkronisasi profil ke tabel 'profiles'
          try {
            await _supabase.from('profiles').upsert({
              'id': response.user!.id,
              'email': email,
              'username': username.isNotEmpty ? username : email.split('@').first,
              'level': 1,
              'total_xp': 0,
              'boss_damage_total': 0,
            });
          } catch (e) {
            debugPrint('Warning: gagal upsert profile ke Supabase: $e');
          }

          // Wajib panggil signOut agar sesi ter-reset bersih sebelum diarahkan ke login
          await _supabase.auth.signOut();
        }
      } catch (e) {
        debugPrint('Supabase signup exception: $e');
      }

      return true;
    } catch (e) {
      _errorMessage = 'Gagal mendaftar: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login dengan Supabase Auth atau fallback kredensial lokal
  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String targetEmail = identifier;

      // Cek apakah identifier adalah username
      final mappedEmail = await _storage.read(key: 'username_to_email_$identifier');
      if (mappedEmail != null) {
        targetEmail = mappedEmail;
      }

      // Coba sign in ke Supabase jika targetEmail berbentuk email
      bool supabaseSuccess = false;
      if (targetEmail.contains('@')) {
        try {
          final res = await _supabase.auth.signInWithPassword(
            email: targetEmail,
            password: password,
          );
          if (res.user != null) {
            supabaseSuccess = true;
          }
        } catch (e) {
          debugPrint('Supabase signIn gagal, mencoba fallback lokal: $e');
        }
      }

      // Validasi lokal jika Supabase offline atau akun terdaftar lokal
      final storedHash = await _storage.read(key: 'reg_password_$targetEmail');
      final bytes = utf8.encode(password);
      final inputHash = sha256.convert(bytes).toString();

      if (supabaseSuccess || storedHash == inputHash) {
        // Set active session
        await _storage.write(key: 'active_email', value: targetEmail);
        final username = await _storage.read(key: 'reg_username_$targetEmail') ??
            targetEmail.split('@').first;
        await _storage.write(key: 'active_username', value: username);
        return true;
      }

      _errorMessage = 'Email/Username atau Password salah!';
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan login: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout bersih: membersihkan sesi Supabase dan cache lokal
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut error: $e');
    }
    await _storage.delete(key: 'active_email');
    await _storage.delete(key: 'active_username');
    notifyListeners();
  }
}

