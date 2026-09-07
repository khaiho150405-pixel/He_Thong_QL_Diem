import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý điểm')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined, size: 56),
                    const SizedBox(height: 24),
                    Text(
                      'Chào mừng bạn',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kiểm tra kết nối đến hệ thống quản lý điểm.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    connection.when(
                      loading: () => const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Đang kết nối…'),
                        ],
                      ),
                      error: (_, stack) => Column(
                        children: [
                          const Text('Không thể kết nối'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => ref.invalidate(connectionProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                      data: (_) => const Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(Icons.check_circle_outline),
                          Text('Kết nối thành công'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
