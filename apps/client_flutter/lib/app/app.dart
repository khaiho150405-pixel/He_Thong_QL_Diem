import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/connection/connection.dart';

final _router = GoRouter(
  routes: [GoRoute(path: '/', builder: (_, state) => const ConnectionScreen())],
);

class GradebookApp extends StatelessWidget {
  const GradebookApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Quản lý điểm',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF176B59),
    ),
    routerConfig: _router,
  );
}
