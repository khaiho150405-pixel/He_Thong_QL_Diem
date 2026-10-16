import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/design_tokens.dart';
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
    final t = context.tokens;

    final content = ColoredBox(
      color: t.bg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: t.line),
                boxShadow: t.shadow,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                  vertical: 36,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [t.pri, t.priHover],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: t.shadow,
                      ),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          Icons.wifi_tethering_rounded,
                          size: 36,
                          color: t.onPri,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Kết nối máy chủ API',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Địa chỉ: ${AppConfig.apiBaseUrl}',
                      style: theme.textTheme.bodySmall?.copyWith(
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
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Đang kiểm tra tín hiệu tới máy chủ…',
                            style: TextStyle(
                              color: t.ink2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      error: (err, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.badSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: t.badLine),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: t.bad,
                                size: 32,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Không thể kết nối',
                                style: TextStyle(
                                  color: t.bad,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: () =>
                                    ref.invalidate(connectionProvider),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (_) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.okSoft,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: t.okLine),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: t.ok,
                                size: 36,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Kết nối thành công',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: t.ok,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Hệ thống sẵn sàng phục vụ yêu cầu.',
                                style: TextStyle(color: t.ink2, fontSize: 12.5),
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
                    ),
                    const SizedBox(height: AppSpacing.xxl),
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
