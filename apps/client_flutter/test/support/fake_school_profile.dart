import 'dart:convert';
import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/school_profile/school_profile.dart';
import 'package:dio/dio.dart';

const fakeSchoolName = 'Trường THPT Thử Nghiệm';
const fakeSchoolShortName = 'THPT Thử Nghiệm';

SchoolProfileDto fakeSchoolProfile({
  String name = fakeSchoolName,
  String shortName = fakeSchoolShortName,
  bool hasLogo = false,
  num version = 1,
}) => SchoolProfileDto(
  name: name,
  shortName: shortName,
  governingBody: null,
  address: null,
  phone: null,
  email: null,
  principal: null,
  hasLogo: hasLogo,
  version: version,
  updatedAt: '2026-10-01T03:00:00.000Z',
);

/// Lỗi API dạng envelope `{code, message, details}`.
DioException apiError(
  String code, {
  int status = 409,
  Map<String, dynamic>? details,
}) {
  final options = RequestOptions(path: '/api/v1/admin/school-profile');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {'code': code, 'message': 'Lỗi từ máy chủ', 'details': ?details},
    ),
  );
}

class FakeSchoolProfileRepository implements SchoolProfileRepository {
  FakeSchoolProfileRepository([SchoolProfileDto? initial])
    : profile = initial ?? fakeSchoolProfile();

  SchoolProfileDto profile;
  Object? updateError;
  bool failFetch = false;
  int updates = 0;

  @override
  Future<SchoolProfileDto> fetch() async {
    if (failFetch) throw apiError('INTERNAL', status: 500);
    return profile;
  }

  @override
  Future<SchoolProfileDto> update(UpdateSchoolProfileInput input) async {
    if (updateError != null) throw updateError!;
    updates++;
    return profile = fakeSchoolProfile(
      name: input.name,
      shortName: input.shortName,
      hasLogo: profile.hasLogo,
      version: profile.version + 1,
    );
  }

  @override
  Future<SchoolProfileDto> setLogo({
    required MultipartFile file,
    required int expectedVersion,
  }) async => profile = fakeSchoolProfile(
    name: profile.name,
    shortName: profile.shortName,
    hasLogo: true,
    version: profile.version + 1,
  );

  @override
  Future<SchoolProfileDto> removeLogo(num expectedVersion) async =>
      profile = fakeSchoolProfile(
        name: profile.name,
        shortName: profile.shortName,
        version: profile.version + 1,
      );
}

/// Máy chủ giả: chỉ trả năm học/học kỳ hiện hành, mọi đường dẫn khác 404.
class FakeCatalogServer implements HttpClientAdapter {
  FakeCatalogServer({this.withTerm = true});
  final bool withTerm;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body = {};
    var status = 404;
    if (options.path.endsWith('/catalog/years')) {
      status = 200;
      body = {
        'items': [
          {
            'ma_nam_hoc': 1,
            'ten': '2031-2032',
            'label': '2031-2032',
            'ngay_bat_dau': '2031-09-01',
            'ngay_ket_thuc': '2032-05-31',
            'hien_hanh': true,
          },
        ],
        'nextCursor': null,
      };
    } else if (options.path.endsWith('/catalog/semesters')) {
      status = 200;
      body = {
        'items': withTerm
            ? [
                {
                  'ma_hoc_ky': 1,
                  'ma_nam_hoc': 1,
                  'ten': 'Học kỳ I',
                  'thu_tu': 1,
                  'label': 'Học kỳ I',
                  'ngay_bat_dau': '2000-01-01',
                  'ngay_ket_thuc': '2999-12-31',
                },
              ]
            : [],
        'nextCursor': null,
      };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }
}
