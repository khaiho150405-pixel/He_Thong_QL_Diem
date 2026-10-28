import 'package:api_client_dart/api_client_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../authentication/session.dart';

abstract class SchoolProfileRepository {
  Future<SchoolProfileDto> fetch();
  Future<SchoolProfileDto> update(UpdateSchoolProfileInput input);
  Future<SchoolProfileDto> setLogo({
    required MultipartFile file,
    required int expectedVersion,
  });
  Future<SchoolProfileDto> removeLogo(num expectedVersion);
}

class ApiSchoolProfileRepository implements SchoolProfileRepository {
  const ApiSchoolProfileRepository(this._api);
  final ApiClientDart _api;

  // Khóa idempotency của API chỉ nhận [a-zA-Z0-9_-], tối đa 64 ký tự.
  static String _key() => 'school-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<SchoolProfileDto> fetch() async =>
      (await _api.getSchoolApi().schoolProfilePublicProfile()).data!;

  @override
  Future<SchoolProfileDto> update(UpdateSchoolProfileInput input) async =>
      (await _api.getSchoolApi().schoolProfileAdminUpdate(
        xIdempotencyKey: _key(),
        updateSchoolProfileInput: input,
      )).data!;

  @override
  Future<SchoolProfileDto> setLogo({
    required MultipartFile file,
    required int expectedVersion,
  }) async => (await _api.getSchoolApi().schoolProfileAdminSetLogo(
    xIdempotencyKey: _key(),
    file: file,
    expectedVersion: expectedVersion,
  )).data!;

  @override
  Future<SchoolProfileDto> removeLogo(num expectedVersion) async =>
      (await _api.getSchoolApi().schoolProfileAdminRemoveLogo(
        expectedVersion: expectedVersion,
        xIdempotencyKey: _key(),
      )).data!;
}

final schoolProfileRepositoryProvider = Provider<SchoolProfileRepository>(
  (ref) => ApiSchoolProfileRepository(ref.watch(apiProvider)),
);

/// Thông tin trường dùng chung (endpoint công khai, gọi được khi chưa đăng
/// nhập). Lỗi/đang tải cho `null` để giao diện hiện chữ trung tính, không chặn
/// đăng nhập. Tải lại khi đăng nhập/đăng xuất; sau khi QTV lưu thì
/// `ref.invalidate(schoolProfileProvider)`.
final schoolProfileProvider = FutureProvider<SchoolProfileDto?>((ref) async {
  ref.watch(sessionProvider.select((user) => user != null));
  try {
    return await ref.watch(schoolProfileRepositoryProvider).fetch();
  } catch (_) {
    return null;
  }
});

/// `?v=<version>` để trình duyệt không giữ logo cũ sau khi đổi.
String schoolLogoUrl(SchoolProfileDto profile) =>
    '${AppConfig.apiBaseUrl}/api/v1/school-profile/logo?v=${profile.version}';

/// Logo trường; không có logo hoặc tải lỗi thì hiện [fallback].
class SchoolLogoImage extends StatelessWidget {
  const SchoolLogoImage({
    super.key,
    required this.profile,
    required this.size,
    required this.fallback,
  });

  final SchoolProfileDto? profile;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null || !p.hasLogo) return fallback;
    return Image.network(
      schoolLogoUrl(p),
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Web: API khác origin với trang, <img> không cần CORS như CanvasKit.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// [SchoolLogoImage] lấy dữ liệu từ [schoolProfileProvider].
class SchoolLogo extends ConsumerWidget {
  const SchoolLogo({super.key, required this.size, required this.fallback});

  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SchoolLogoImage(
    profile: ref.watch(schoolProfileProvider).valueOrNull,
    size: size,
    fallback: fallback,
  );
}
