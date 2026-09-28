import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/session.dart';
import 'timetable_model.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  final api = ref.watch(apiProvider);
  return TimetableRepository(api.dio);
});

class TimetableRepository {
  final dynamic dio;
  TimetableRepository(this.dio);

  Future<List<TimetableItem>> getTimetable({
    num? classId,
    num? teacherId,
    num? semesterId,
    int? dayOfWeek,
  }) async {
    final query = <String, dynamic>{};
    if (classId != null) query['classId'] = classId.toInt();
    if (teacherId != null) query['teacherId'] = teacherId.toInt();
    if (semesterId != null) query['semesterId'] = semesterId.toInt();
    if (dayOfWeek != null) query['dayOfWeek'] = dayOfWeek;

    final response = await dio.get('/api/v1/timetable', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => TimetableItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> createItem({
    required int maLop,
    required int maMon,
    required int maGiaoVien,
    required int maHocKy,
    required int thu,
    required int tiet,
    String? phongHoc,
    String? ghiChu,
  }) async {
    await dio.post(
      '/api/v1/timetable',
      data: {
        'ma_lop': maLop,
        'ma_mon': maMon,
        'ma_giao_vien': maGiaoVien,
        'ma_hoc_ky': maHocKy,
        'thu': thu,
        'tiet': tiet,
        'phong_hoc': phongHoc,
        'ghi_chu': ghiChu,
      },
    );
  }

  Future<void> updateItem({
    required int id,
    required int maLop,
    required int maMon,
    required int maGiaoVien,
    required int maHocKy,
    required int thu,
    required int tiet,
    String? phongHoc,
    String? ghiChu,
  }) async {
    await dio.put(
      '/api/v1/timetable/$id',
      data: {
        'ma_lop': maLop,
        'ma_mon': maMon,
        'ma_giao_vien': maGiaoVien,
        'ma_hoc_ky': maHocKy,
        'thu': thu,
        'tiet': tiet,
        'phong_hoc': phongHoc,
        'ghi_chu': ghiChu,
      },
    );
  }

  Future<void> deleteItem(int id) async {
    await dio.delete('/api/v1/timetable/$id');
  }
}
