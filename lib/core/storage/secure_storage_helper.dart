import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  static const String _keyToken = 'jwt_token';
  static const String _keyEmail = 'user_email';

  static Future<void> saveSession(String token, String email) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyEmail, value: email);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<String?> getEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  static Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyEmail);
  }
}