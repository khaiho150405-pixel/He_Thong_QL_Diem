import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/connection/connection.dart';
import '../features/authentication/session.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/home_screen.dart';
import '../features/academic_catalog/catalog_screen.dart';
import '../features/academic_catalog/fields.dart';
import '../features/gradebooks/gradebook_screen.dart';
import '../features/gradebooks/gradebooks_screen.dart';

final routerProvider = Provider.family<GoRouter, String>((
  ref,
  initialLocation,
) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, state) => const LoginScreen()),
      GoRoute(
        path: '/connection',
        builder: (_, state) => const ConnectionScreen(),
      ),
      GoRoute(
        path: '/catalog/:resource',
        builder: (_, state) =>
            CatalogScreen(resource: state.pathParameters['resource']!),
      ),
      GoRoute(
        path: '/gradebooks',
        builder: (_, state) => const GradebooksScreen(),
      ),
      GoRoute(
        path: '/gradebooks/:id',
        builder: (_, state) {
          final id = num.tryParse(state.pathParameters['id'] ?? '');
          return id == null
              ? const GradebooksScreen()
              : GradebookScreen(bookId: id);
        },
      ),
    ],
    redirect: (context, state) {
      if (state.uri.path == '/connection') return null;
      final user = ref.read(sessionProvider);
      if (user == null) return state.uri.path == '/login' ? null : '/login';
      if (state.uri.path == '/login') return '/';
      if (state.uri.path.startsWith('/gradebooks') &&
          user.role.value == 'HOC_SINH') {
        return '/';
      }
      final resource = state.pathParameters['resource'];
      if (resource != null &&
          (!resources.any((r) => r.key == resource) ||
              (user.role.value == 'HOC_SINH' && resource != 'students') ||
              (user.role.value == 'GIAO_VIEN' && resource == 'accounts'))) {
        return '/';
      }
      return null;
    },
  );
  ref.listen(sessionProvider, (_, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

class GradebookApp extends ConsumerWidget {
  const GradebookApp({
    super.key,
    this.initialLocation =
        const bool.fromEnvironment('EXPECT_TRANSIENT_FAILURE')
        ? '/connection'
        : '/',
  });
  final String initialLocation;
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Quản lý điểm',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF176B59),
    ),
    routerConfig: ref.watch(routerProvider(initialLocation)),
  );
}
