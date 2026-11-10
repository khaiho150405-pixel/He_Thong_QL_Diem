import 'package:flutter/foundation.dart';

class AppConfig {
  static const _envFromDefine = String.fromEnvironment('APP_ENV');
  static const _apiFromDefine = String.fromEnvironment('API_BASE_URL');

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

  static String get apiBaseUrl {
    if (kIsWeb) {
      final scheme = Uri.base.scheme.toLowerCase();
      final host = Uri.base.host.toLowerCase();

      if (scheme == 'https' || host.contains('eduscore.id.vn')) {
        if (_apiFromDefine.isNotEmpty &&
            _apiFromDefine.startsWith('https://')) {
          return _apiFromDefine;
        }
        return 'https://api.eduscore.id.vn';
      }

      if (host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '0.0.0.0' ||
          host.isEmpty) {
        if (_apiFromDefine.isNotEmpty &&
            !_apiFromDefine.contains('api.eduscore.id.vn')) {
          return _apiFromDefine;
        }
        return 'http://localhost:3000';
      }

      return 'http://$host:3000';
    }

    if (_apiFromDefine.isNotEmpty) {
      return _apiFromDefine;
    }
    return 'http://localhost:3000';
  }

  static void validate() {
    try {
      final env = environment;
      final api = apiBaseUrl;
      debugPrint('[AppConfig] Khoi dong voi APP_ENV=$env | API_BASE_URL=$api');
    } catch (e) {
      debugPrint('[AppConfig] Canh bao cau hinh: $e');
    }
  }
}
