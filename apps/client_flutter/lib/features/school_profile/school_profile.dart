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

final schoolProfileProvider = FutureProvider<SchoolProfileDto?>((ref) async {
  ref.watch(sessionProvider.select((user) => user != null));
  try {
    return await ref.watch(schoolProfileRepositoryProvider).fetch();
  } catch (_) {
    return null;
  }
});

String schoolLogoUrl(SchoolProfileDto profile) =>
    '${AppConfig.apiBaseUrl}/api/v1/school-profile/logo?v=${profile.version}';

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
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

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
