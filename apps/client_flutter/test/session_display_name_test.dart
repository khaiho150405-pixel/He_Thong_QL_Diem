import 'package:api_client_dart/api_client_dart.dart';
import 'package:client_flutter/features/authentication/session.dart';
import 'package:flutter_test/flutter_test.dart';

SessionDto _session({String? displayName}) => SessionDto(
  id: 1,
  username: '0903112233',
  displayName: displayName,
  role: SessionDtoRoleEnum.GIAO_VIEN,
  active: true,
  token: 't',
  csrf: 'c',
);

void main() {
  test('có họ tên thì hiển thị họ tên', () {
    expect(_session(displayName: 'Phạm Thu Hà').shownName, 'Phạm Thu Hà');
  });

  test('họ tên có khoảng trắng thừa được cắt gọn', () {
    expect(
      _session(displayName: '  Trần Minh Anh ').shownName,
      'Trần Minh Anh',
    );
  });

  test('không có hoặc rỗng thì dùng tên đăng nhập', () {
    expect(_session().shownName, '0903112233');
    expect(_session(displayName: '   ').shownName, '0903112233');
  });
}
