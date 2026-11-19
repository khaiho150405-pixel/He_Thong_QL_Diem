import 'dart:convert';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';
import 'timetable_model.dart';
import 'timetable_repository.dart';

const scheduleWidgetChannelName = 'vn.edu.quanlydiem/schedule_widget';

final RegExp _slotTimes = RegExp(r'^(\d{2}:\d{2}) - (\d{2}:\d{2})$');

String _isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic>? buildScheduleWidgetPayload({
  required SessionDtoRoleEnum role,
  required TimetableResult result,
}) {
  final isStudent = role == SessionDtoRoleEnum.HOC_SINH;
  if (!isStudent && role != SessionDtoRoleEnum.GIAO_VIEN) return null;

  final lessons = <Map<String, dynamic>>[];
  for (final item in result.items) {
    final times = _slotTimes.firstMatch(item.timeSlotLabel);
    final detail = isStudent
        ? item.tenGiaoVien
        : [
            if (item.tenLop.isNotEmpty) 'Lớp ${item.tenLop}',
            if ((item.phongHoc ?? '').trim().isNotEmpty)
              'Phòng ${item.phongHoc!.trim()}',
          ].join(' · ');
    lessons.add({
      'thu': item.thu,
      'tiet': item.tiet,
      'subject': item.tenMon,
      'detail': detail,
      'start': times?.group(1),
      'end': times?.group(2),
    });
  }

  final semester = result.semester;
  final className = result.items.isEmpty ? null : result.items.first.tenLop;
  return {
    'role': role.name,
    'title': isStudent
        ? (className == null || className.isEmpty
              ? 'Thời khóa biểu'
              : 'Thời khóa biểu $className')
        : 'Lịch dạy',
    'semester': semester == null
        ? null
        : {
            'name': '${semester.name} · ${semester.yearName}',
            'start': _isoDay(semester.startDate),
            'end': _isoDay(semester.endDate),
          },
    'lessons': lessons,
  };
}

class ScheduleWidgetBridge {
  const ScheduleWidgetBridge();

  static const MethodChannel _channel = MethodChannel(
    scheduleWidgetChannelName,
  );

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> save(Map<String, dynamic> payload) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('save', jsonEncode(payload));
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<void> clear() async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('clear');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

final scheduleWidgetBridgeProvider = Provider<ScheduleWidgetBridge>(
  (ref) => const ScheduleWidgetBridge(),
);

class ScheduleWidgetHost extends ConsumerStatefulWidget {
  const ScheduleWidgetHost({
    super.key,
    required this.child,
    this.minRefreshGap = const Duration(minutes: 5),
  });

  final Widget child;
  final Duration minRefreshGap;

  @override
  ConsumerState<ScheduleWidgetHost> createState() => _ScheduleWidgetHostState();
}

class _ScheduleWidgetHostState extends ConsumerState<ScheduleWidgetHost>
    with WidgetsBindingObserver {
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(sessionProvider);
      if (mounted && session != null) _sync(session);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final session = ref.read(sessionProvider);
    final last = _lastSync;
    if (session == null) return;
    if (last != null &&
        DateTime.now().difference(last) < widget.minRefreshGap) {
      return;
    }
    _sync(session);
  }

  Future<void> _sync(SessionDto session) async {
    final bridge = ref.read(scheduleWidgetBridgeProvider);
    if (!bridge.supported) return;
    if (session.role != SessionDtoRoleEnum.HOC_SINH &&
        session.role != SessionDtoRoleEnum.GIAO_VIEN) {
      await bridge.clear();
      return;
    }
    _lastSync = DateTime.now();
    try {
      final result = await ref.read(timetableRepositoryProvider).getTimetable();
      if (!mounted || ref.read(sessionProvider)?.id != session.id) return;
      final payload = buildScheduleWidgetPayload(
        role: session.role,
        result: result,
      );
      if (payload != null) await bridge.save(payload);
    } catch (_) {
      _lastSync = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionDto?>(sessionProvider, (previous, next) {
      if (next == null) {
        if (previous != null) ref.read(scheduleWidgetBridgeProvider).clear();
        return;
      }
      if (previous?.id != next.id) _sync(next);
    });
    return widget.child;
  }
}
