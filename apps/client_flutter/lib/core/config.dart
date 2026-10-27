import 'package:flutter/foundation.dart';

class AppConfig {
  static const _envFromDefine = String.fromEnvironment('APP_ENV');
  static const _apiFromDefine = String.fromEnvironment('API_BASE_URL');

  /// Tự động xác định môi trường (development, staging, production)
  static String get environment {
    if (_envFromDefine.isNotEmpty) return _envFromDefine;
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host.contains('eduscore.id.vn') || Uri.base.scheme == 'https') {
        return 'production';
      }
    }
    return 'development';
  }

  /// Tự động xác định API Base URL phù hợp:
  /// - Khi mở ở tên miền https://eduscore.id.vn -> tự động trỏ về https://api.eduscore.id.vn
  /// - Khi mở ở localhost / 127.0.0.1 -> tự động trỏ về http://localhost:3000
  /// - Khi mở qua mạng LAN (http://192.168.x.x:8080) -> trỏ về http://<host>:3000
  /// - Không bao giờ để lỗi Mixed Content (trang HTTPS gọi API HTTP) làm trắng màn hình
  static String get apiBaseUrl {
    if (kIsWeb) {
      final scheme = Uri.base.scheme.toLowerCase();
      final host = Uri.base.host.toLowerCase();

      // Nếu đang mở trang web bằng HTTPS hoặc qua tên miền eduscore.id.vn
      if (scheme == 'https' || host.contains('eduscore.id.vn')) {
        if (_apiFromDefine.isNotEmpty && _apiFromDefine.startsWith('https://')) {
          return _apiFromDefine;
        }
        return 'https://api.eduscore.id.vn';
      }

      // Đang mở ở localhost hoặc 127.0.0.1
      if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0' || host.isEmpty) {
        if (_apiFromDefine.isNotEmpty && !_apiFromDefine.contains('api.eduscore.id.vn')) {
          return _apiFromDefine;
        }
        return 'http://localhost:3000';
      }

      // Mở qua IP mạng nội bộ LAN (ví dụ http://192.168.1.5:8080)
      return 'http://$host:3000';
    }

    if (_apiFromDefine.isNotEmpty) {
      return _apiFromDefine;
    }
    return 'http://localhost:3000';
  }

  static void validate() {
    // Đảm bảo không bao giờ ném exception làm chết ứng dụng khiến người dùng bị trắng màn hình
    try {
      final env = environment;
      final api = apiBaseUrl;
      debugPrint('[AppConfig] Khoi dong voi APP_ENV=$env | API_BASE_URL=$api');
    } catch (e) {
      debugPrint('[AppConfig] Canh bao cau hinh: $e');
    }
  }
}

