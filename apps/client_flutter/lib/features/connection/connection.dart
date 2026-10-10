import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/app_scaffold.dart';
import '../../core/config.dart';
import '../authentication/session.dart';

final connectionProvider = FutureProvider<void>((ref) async {
  AppConfig.validate();
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  final api = ApiClientDart(dio: dio);
  await api.getHealthApi().healthLive();
});

class ConnectionScreen extends ConsumerWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionProvider);
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorScheme.primary.withAlpha(15), colorScheme.surface],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(120),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withAlpha(200),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withAlpha(60),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wifi_tethering_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kết nối máy chủ API',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Địa chỉ: ${AppConfig.apiBaseUrl}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    connection.when(
                      loading: () => Column(
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Đang kiểm tra tín hiệu tới máy chủ…',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withAlpha(100),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.error.withAlpha(70),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: colorScheme.error,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            const Text('Không thể kết nối'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  ref.invalidate(connectionProvider),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      ),
                      data: (_) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade700,
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Kết nối thành công',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.green.shade900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hệ thống sẵn sàng phục vụ yêu cầu.',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton(
                              onPressed: () =>
                                  ref.invalidate(connectionProvider),
                              child: const Text('Kiểm tra lại'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Quay lại màn hình trước'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (session != null) {
      return AppScaffold(
        title: 'Kiểm tra kết nối',
        currentPath: '/connection',
        showBackButton: true,
        onBack: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/');
          }
        },
        body: content,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra kết nối'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: content,
    );
  }
}
