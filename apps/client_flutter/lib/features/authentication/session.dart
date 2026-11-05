import 'dart:async';
import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';
import '../../core/remember_store.dart';
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
  // Tunnel/API khởi động lại hoặc mạng chập chờn: tự thử lại yêu cầu đọc (GET) tối đa 2 lần trước khi báo lỗi.
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final options = error.requestOptions;
        final attempt = (options.extra['retryAttempt'] as int?) ?? 0;
        if (options.method != 'GET' || attempt >= 2 || !_transient(error)) {
          return handler.next(error);
        }
        await Future<void>.delayed(Duration(milliseconds: 700 * (attempt + 1)));
        options.extra['retryAttempt'] = attempt + 1;
        try {
          handler.resolve(await dio.fetch<dynamic>(options));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        ref.read(sessionProvider.notifier).touch();
        handler.next(response);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final unauthorized =
            error.response?.statusCode == 401 &&
            !path.endsWith('/login') &&
            !path.endsWith('/resume');
        if (!unauthorized) return handler.next(error);
        final session = ref.read(sessionProvider.notifier);
        // App di động: phiên hết hạn → đổi mã ghi nhớ lấy phiên mới rồi gửi lại đúng yêu cầu đó một lần.
        if (!kIsWeb && error.requestOptions.extra['resumed'] != true) {
          if (await session.resume()) {
            try {
              final retry = error.requestOptions
                ..extra['resumed'] = true
                ..headers['authorization'] =
                    dio.options.headers['authorization']
                ..headers['x-csrf-token'] = dio.options.headers['x-csrf-token'];
              return handler.resolve(await dio.fetch<dynamic>(retry));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        session.clear();
        handler.next(error);
      },
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return ApiClientDart(dio: dio);
});

bool _transient(DioException e) {
  final code = e.response?.statusCode;
  if (code != null) return code == 502 || code == 503 || code == 504;
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };
}

final StateNotifierProvider<SessionController, SessionDto?> sessionProvider =
    StateNotifierProvider<SessionController, SessionDto?>(
      (ref) => SessionController(ref.read(apiProvider)),
    );

class SessionController extends StateNotifier<SessionDto?> {
  SessionController(this.api, {RememberStore? store})
    : store = store ?? const SecureRememberStore(),
      super(null) {
    Future.microtask(kIsWeb ? restore : resume);
  }
  final ApiClientDart api;
  final RememberStore store;
  Timer? expiry;
  Future<bool>? _resuming;

  /// App di động: mở lại app (hoặc phiên hết hạn) → đổi mã ghi nhớ đã lưu lấy phiên mới.
  /// Gọi đồng thời dùng chung một lần đổi vì mã chỉ dùng được một lần.
  Future<bool> resume() =>
      _resuming ??= _resume().whenComplete(() => _resuming = null);

  Future<bool> _resume() async {
    final saved = await store.read();
    if (saved == null || saved.isEmpty) return false;
    try {
      final response = await api.getIdentityApi().identityResume(
        xRememberToken: saved,
        xClientPlatform: 'native',
      );
      if (!mounted) return false;
      await _accept(response);
      return true;
    } on DioException catch (e) {
      // Chỉ bỏ mã khi server từ chối; mất mạng thì giữ để thử lại lần sau.
      if (e.response?.statusCode == 401) await store.delete();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _accept(Response<SessionDto> response) async {
    final session = response.data!;
    api.dio.options.headers['x-csrf-token'] = session.csrf;
    api.dio.options.headers['authorization'] = 'Bearer ${session.token}';
    final next = response.headers.value('x-remember-token');
    if (next != null && next.isNotEmpty) await store.write(next);
    state = session;
  }

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
    // App di động giữ đăng nhập qua mã ghi nhớ; phiên hết hạn được tự đổi mới ở interceptor.
    if (!kIsWeb) return;
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
      xClientPlatform: kIsWeb ? 'web' : 'native',
      loginInput: LoginInput(username: username.trim(), password: password),
    );
    if (kIsWeb) {
      final session = response.data!;
      api.dio.options.headers['x-csrf-token'] = session.csrf;
      state = session;
      touch();
    } else {
      await _accept(response);
    }
  }

  Future<void> logout() async {
    try {
      await api.getIdentityApi().identityLogout();
    } finally {
      unawaited(store.delete());
      clear();
    }
  }

  void clear() {
    expiry?.cancel();
    api.dio.options.headers.remove('authorization');
    api.dio.options.headers.remove('x-csrf-token');
    state = null;
  }
}

/// Máy chủ trả câu chung chung (hoặc rỗng) khi không chỉ rõ nguyên nhân.
bool _isGenericServerMessage(String? message) {
  final normalized = message?.trim().toLowerCase() ?? '';
  return normalized.isEmpty ||
      normalized == 'yêu cầu không hợp lệ.' ||
      normalized == 'bad request' ||
      normalized == 'conflict';
}

String errorMessage(Object error) {
  if (error is DioException) {
    final responseData = error.response?.data;
    final serverMessage = responseData is Map<String, dynamic>
        ? responseData['message']?.toString()
        : null;
    return switch (error.response?.statusCode) {
      // Máy chủ trả câu chung "Yêu cầu không hợp lệ." khi không chỉ rõ trường nào:
      // dùng gợi ý cụ thể hơn thay vì hiện nguyên câu đó.
      400 =>
        _isGenericServerMessage(serverMessage)
            ? 'Thông tin chưa hợp lệ. Kiểm tra các trường và khoảng ngày.'
            : serverMessage!,
      401 =>
        'Thông tin đăng nhập không đúng, tài khoản tạm khóa hoặc phiên đã hết hạn.',
      403 => serverMessage ?? 'Bạn không có quyền thực hiện thao tác này.',
      409 =>
        _isGenericServerMessage(serverMessage)
            ? 'Dữ liệu trùng, đang được sử dụng hoặc vừa thay đổi (ví dụ môn đã có bảng điểm thì không đổi được thành phần điểm). Kiểm tra lại rồi thử lại.'
            : serverMessage!,
      429 => 'Bạn thử quá nhiều lần. Vui lòng chờ một phút.',
      final code when code != null && code >= 500 =>
        'Máy chủ đang bận hoặc đang khởi động lại (mã $code). Vui lòng thử lại sau ít phút.',
      _ => switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Kết nối quá chậm. Kiểm tra mạng rồi thử lại.',
        _ => 'Không thể kết nối dịch vụ. Kiểm tra mạng và thử lại.',
      },
    };
  }
  return 'Chưa thể thực hiện. Kiểm tra thông tin và thử lại.';
}
