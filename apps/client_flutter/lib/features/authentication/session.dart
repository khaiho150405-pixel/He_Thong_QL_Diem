import 'dart:async';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';
import '../../core/browser_stub.dart'
    if (dart.library.js_interop) '../../core/browser_web.dart';

final Provider<ApiClientDart> apiProvider = Provider<ApiClientDart>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'x-client-platform': kIsWeb ? 'web' : 'native'},
    ),
  );
  configureBrowser(dio);
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        ref.read(sessionProvider.notifier).touch();
        handler.next(response);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.endsWith('/login')) {
          ref.read(sessionProvider.notifier).clear();
        }
        handler.next(error);
      },
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return ApiClientDart(dio: dio);
});

final StateNotifierProvider<SessionController, SessionDto?> sessionProvider =
    StateNotifierProvider<SessionController, SessionDto?>(
      (ref) => SessionController(ref.read(apiProvider)),
    );

class SessionController extends StateNotifier<SessionDto?> {
  SessionController(this.api) : super(null) {
    if (kIsWeb) Future.microtask(restore);
  }
  final ApiClientDart api;
  Timer? expiry;
  Future<void> restore() async {
    try {
      final session = (await api.getIdentityApi().identityMe()).data!;
      if (!mounted) return;
      api.dio.options.headers['x-csrf-token'] = session.csrf;
      state = session;
      touch();
    } catch (_) {
      if (mounted) clear();
    }
  }

  void touch() {
    if (state != null) {
      expiry?.cancel();
      expiry = Timer(const Duration(minutes: 30), clear);
    }
  }

  @override
  void dispose() {
    expiry?.cancel();
    super.dispose();
  }

  Future<void> login(String username, String password) async {
    final response = await api.getIdentityApi().identityLogin(
      loginInput: LoginInput(username: username.trim(), password: password),
    );
    final session = response.data!;
    api.dio.options.headers['x-csrf-token'] = session.csrf;
    if (!kIsWeb) {
      api.dio.options.headers['authorization'] = 'Bearer ${session.token}';
    }
    state = session;
    touch();
  }

  Future<void> logout() async {
    await api.getIdentityApi().identityLogout();
    clear();
  }

  void clear() {
    expiry?.cancel();
    api.dio.options.headers.remove('authorization');
    api.dio.options.headers.remove('x-csrf-token');
    state = null;
  }
}

String errorMessage(Object error) {
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      400 => 'Thông tin chưa hợp lệ. Kiểm tra các trường và khoảng ngày.',
      401 =>
        'Thông tin đăng nhập không đúng, tài khoản tạm khóa hoặc phiên đã hết hạn.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      409 =>
        'Dữ liệu trùng, đã được sử dụng hoặc vừa thay đổi. Tải lại và kiểm tra.',
      429 => 'Bạn thử quá nhiều lần. Vui lòng chờ một phút.',
      _ => 'Không thể kết nối dịch vụ. Vui lòng thử lại.',
    };
  }
  return 'Chưa thể thực hiện. Kiểm tra thông tin và thử lại.';
}
