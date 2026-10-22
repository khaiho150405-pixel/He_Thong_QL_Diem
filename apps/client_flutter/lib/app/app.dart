import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'theme_mode.dart';
import '../features/connection/connection.dart';
import '../features/authentication/session.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/home_screen.dart';
import '../features/academic_catalog/catalog_screen.dart';
import '../features/academic_catalog/fields.dart';
import '../features/academic_catalog/semester_deadlines_screen.dart';
import '../features/academic_catalog/subjects_weights_screen.dart';
import '../features/academic_catalog/teaching_assignments_screen.dart';
import '../features/form_templates/form_templates_screen.dart';
import '../features/form_templates/template_detail_screen.dart';
import '../features/form_templates/template_wizard_screen.dart';
import '../features/gradebooks/adjustments_screen.dart';
import '../features/gradebooks/gradebook_screen.dart';
import '../features/gradebooks/gradebooks_screen.dart';
import '../features/recognition/batch_result_screen.dart';
import '../features/recognition/review_screen.dart';
import '../features/final_results/student_results_screen.dart';
import '../features/final_results/classification_policy_screen.dart';
import '../features/final_results/final_results_screen.dart';
import '../features/timetable/timetable_screen.dart';

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
        path: '/my-results',
        builder: (_, state) => const StudentResultsScreen(),
      ),
      GoRoute(
        path: '/timetable',
        builder: (_, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: '/classification-policy',
        builder: (_, state) => const ClassificationPolicyScreen(),
      ),
      GoRoute(
        path: '/catalog/:resource',
        builder: (_, state) =>
            CatalogScreen(resource: state.pathParameters['resource']!),
      ),
      GoRoute(
        path: '/admin/teaching-assignments',
        builder: (_, state) => const TeachingAssignmentsScreen(),
      ),
      GoRoute(
        path: '/admin/subjects-weights',
        builder: (_, state) => const SubjectsWeightsScreen(),
      ),
      GoRoute(
        path: '/admin/semester-deadlines',
        builder: (_, state) => const SemesterDeadlinesScreen(),
      ),
      GoRoute(
        path: '/admin/form-templates',
        builder: (_, state) => const FormTemplatesScreen(),
      ),
      // `new` = trình hướng dẫn tạo mẫu; còn lại là mã mẫu (màn chi tiết).
      GoRoute(
        path: '/admin/form-templates/:id',
        builder: (_, state) {
          final raw = state.pathParameters['id'] ?? '';
          if (raw == 'new') return const TemplateWizardScreen();
          final id = num.tryParse(raw);
          return id == null
              ? const FormTemplatesScreen()
              : TemplateDetailScreen(templateId: id);
        },
      ),
      GoRoute(
        path: '/adjustments',
        builder: (_, state) => const AdjustmentsScreen(),
      ),
      GoRoute(
        path: '/final-results',
        builder: (_, state) => const FinalResultsScreen(),
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
      GoRoute(
        path: '/gradebooks/:id/recognition/:ticketId',
        builder: (_, state) {
          final id = num.tryParse(state.pathParameters['id'] ?? '');
          final ticketId = state.pathParameters['ticketId'] ?? '';
          return id == null || ticketId.isEmpty
              ? const GradebooksScreen()
              : ReviewScreen(
                  gradebookId: id,
                  ticketId: ticketId,
                  gradebookVersion: state.extra as num?,
                  showPageLabels: state.uri.queryParameters['batch'] == '1',
                );
        },
      ),
      // Kết quả lô nhận dạng theo mẫu (ADR-0016 mục 5): tab theo thành phần.
      GoRoute(
        path: '/gradebooks/:id/recognition-batches/:batchId',
        builder: (_, state) {
          final id = num.tryParse(state.pathParameters['id'] ?? '');
          final batchId = state.pathParameters['batchId'] ?? '';
          return id == null || batchId.isEmpty
              ? const GradebooksScreen()
              : BatchResultScreen(gradebookId: id, batchId: batchId);
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
      if (state.uri.path == '/my-results' && user.role.value != 'HOC_SINH') {
        return '/';
      }
      if (state.uri.path == '/classification-policy' &&
          user.role.value != 'QUAN_TRI_VIEN') {
        return '/';
      }
      // Route mới (bước 13): chỉ thêm điều kiện, không sửa điều kiện cũ.
      if ((state.uri.path == '/admin/teaching-assignments' ||
              state.uri.path == '/admin/subjects-weights' ||
              state.uri.path == '/admin/semester-deadlines') &&
          user.role.value != 'QUAN_TRI_VIEN') {
        return '/';
      }
      // Mẫu bảng điểm (ADR-0016): chỉ QTV, cả màn danh sách lẫn chi tiết.
      if (state.uri.path.startsWith('/admin/form-templates') &&
          user.role.value != 'QUAN_TRI_VIEN') {
        return '/';
      }
      if (state.uri.path == '/adjustments' &&
          user.role.value != 'QUAN_TRI_VIEN') {
        return '/';
      }
      if (state.uri.path == '/final-results' && user.role.value == 'HOC_SINH') {
        return '/';
      }
      final resource = state.pathParameters['resource'];
      if (resource != null &&
          (!resources.any((r) => r.key == resource) ||
              user.role.value != 'QUAN_TRI_VIEN')) {
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
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ref.watch(themeModeProvider),
    scrollBehavior: const AppScrollBehavior(),
    routerConfig: ref.watch(routerProvider(initialLocation)),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('vi'), Locale('en')],
    locale: const Locale('vi'),
  );
}
