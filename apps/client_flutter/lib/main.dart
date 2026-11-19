import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config.dart';
import 'features/timetable/schedule_widget_sync.dart';

void main() {
  AppConfig.validate();
  runApp(const ProviderScope(child: ScheduleWidgetHost(child: GradebookApp())));
}
