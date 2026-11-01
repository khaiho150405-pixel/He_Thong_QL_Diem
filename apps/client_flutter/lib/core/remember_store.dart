import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Nơi giữ mã ghi nhớ đăng nhập trên app di động (Keychain iOS / Keystore Android).
/// Web dùng cookie HttpOnly do backend quản lý nên không lưu gì ở đây.
/// Mọi lỗi lưu trữ được nuốt: thiếu kho an toàn chỉ có nghĩa là phải đăng nhập lại.
abstract class RememberStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureRememberStore implements RememberStore {
  const SecureRememberStore();
  static const _key = 'remember_token';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() async {
    if (kIsWeb) return null;
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String token) async {
    if (kIsWeb) return;
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {}
  }

  @override
  Future<void> delete() async {
    if (kIsWeb) return;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
