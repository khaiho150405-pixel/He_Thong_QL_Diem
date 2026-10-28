// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_school_profile_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateSchoolProfileInputCWProxy {
  UpdateSchoolProfileInput expectedVersion(num expectedVersion);

  UpdateSchoolProfileInput name(String name);

  UpdateSchoolProfileInput shortName(String shortName);

  UpdateSchoolProfileInput governingBody(String? governingBody);

  UpdateSchoolProfileInput address(String? address);

  UpdateSchoolProfileInput phone(String? phone);

  UpdateSchoolProfileInput email(String? email);

  UpdateSchoolProfileInput principal(String? principal);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdateSchoolProfileInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdateSchoolProfileInput(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdateSchoolProfileInput call({
    num expectedVersion,
    String name,
    String shortName,
    String? governingBody,
    String? address,
    String? phone,
    String? email,
    String? principal,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUpdateSchoolProfileInput.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUpdateSchoolProfileInput.copyWith.fieldName(...)`
class _$UpdateSchoolProfileInputCWProxyImpl
    implements _$UpdateSchoolProfileInputCWProxy {
  const _$UpdateSchoolProfileInputCWProxyImpl(this._value);

  final UpdateSchoolProfileInput _value;

  @override
  UpdateSchoolProfileInput expectedVersion(num expectedVersion) =>
      this(expectedVersion: expectedVersion);

  @override
  UpdateSchoolProfileInput name(String name) => this(name: name);

  @override
  UpdateSchoolProfileInput shortName(String shortName) =>
      this(shortName: shortName);

  @override
  UpdateSchoolProfileInput governingBody(String? governingBody) =>
      this(governingBody: governingBody);

  @override
  UpdateSchoolProfileInput address(String? address) => this(address: address);

  @override
  UpdateSchoolProfileInput phone(String? phone) => this(phone: phone);

  @override
  UpdateSchoolProfileInput email(String? email) => this(email: email);

  @override
  UpdateSchoolProfileInput principal(String? principal) =>
      this(principal: principal);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdateSchoolProfileInput(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdateSchoolProfileInput(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdateSchoolProfileInput call({
    Object? expectedVersion = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? shortName = const $CopyWithPlaceholder(),
    Object? governingBody = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? principal = const $CopyWithPlaceholder(),
  }) {
    return UpdateSchoolProfileInput(
      expectedVersion: expectedVersion == const $CopyWithPlaceholder()
          ? _value.expectedVersion
          // ignore: cast_nullable_to_non_nullable
          : expectedVersion as num,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      shortName: shortName == const $CopyWithPlaceholder()
          ? _value.shortName
          // ignore: cast_nullable_to_non_nullable
          : shortName as String,
      governingBody: governingBody == const $CopyWithPlaceholder()
          ? _value.governingBody
          // ignore: cast_nullable_to_non_nullable
          : governingBody as String?,
      address: address == const $CopyWithPlaceholder()
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String?,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      principal: principal == const $CopyWithPlaceholder()
          ? _value.principal
          // ignore: cast_nullable_to_non_nullable
          : principal as String?,
    );
  }
}

extension $UpdateSchoolProfileInputCopyWith on UpdateSchoolProfileInput {
  /// Returns a callable class that can be used as follows: `instanceOfUpdateSchoolProfileInput.copyWith(...)` or like so:`instanceOfUpdateSchoolProfileInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateSchoolProfileInputCWProxy get copyWith =>
      _$UpdateSchoolProfileInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateSchoolProfileInput _$UpdateSchoolProfileInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateSchoolProfileInput', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['expectedVersion', 'name', 'shortName'],
  );
  final val = UpdateSchoolProfileInput(
    expectedVersion: $checkedConvert('expectedVersion', (v) => v as num),
    name: $checkedConvert('name', (v) => v as String),
    shortName: $checkedConvert('shortName', (v) => v as String),
    governingBody: $checkedConvert('governingBody', (v) => v as String?),
    address: $checkedConvert('address', (v) => v as String?),
    phone: $checkedConvert('phone', (v) => v as String?),
    email: $checkedConvert('email', (v) => v as String?),
    principal: $checkedConvert('principal', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$UpdateSchoolProfileInputToJson(
  UpdateSchoolProfileInput instance,
) => <String, dynamic>{
  'expectedVersion': instance.expectedVersion,
  'name': instance.name,
  'shortName': instance.shortName,
  'governingBody': ?instance.governingBody,
  'address': ?instance.address,
  'phone': ?instance.phone,
  'email': ?instance.email,
  'principal': ?instance.principal,
};
