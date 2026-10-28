// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_profile_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SchoolProfileDtoCWProxy {
  SchoolProfileDto name(String name);

  SchoolProfileDto shortName(String shortName);

  SchoolProfileDto governingBody(String? governingBody);

  SchoolProfileDto address(String? address);

  SchoolProfileDto phone(String? phone);

  SchoolProfileDto email(String? email);

  SchoolProfileDto principal(String? principal);

  SchoolProfileDto hasLogo(bool hasLogo);

  SchoolProfileDto version(num version);

  SchoolProfileDto updatedAt(String updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SchoolProfileDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SchoolProfileDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SchoolProfileDto call({
    String name,
    String shortName,
    String? governingBody,
    String? address,
    String? phone,
    String? email,
    String? principal,
    bool hasLogo,
    num version,
    String updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSchoolProfileDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSchoolProfileDto.copyWith.fieldName(...)`
class _$SchoolProfileDtoCWProxyImpl implements _$SchoolProfileDtoCWProxy {
  const _$SchoolProfileDtoCWProxyImpl(this._value);

  final SchoolProfileDto _value;

  @override
  SchoolProfileDto name(String name) => this(name: name);

  @override
  SchoolProfileDto shortName(String shortName) => this(shortName: shortName);

  @override
  SchoolProfileDto governingBody(String? governingBody) =>
      this(governingBody: governingBody);

  @override
  SchoolProfileDto address(String? address) => this(address: address);

  @override
  SchoolProfileDto phone(String? phone) => this(phone: phone);

  @override
  SchoolProfileDto email(String? email) => this(email: email);

  @override
  SchoolProfileDto principal(String? principal) => this(principal: principal);

  @override
  SchoolProfileDto hasLogo(bool hasLogo) => this(hasLogo: hasLogo);

  @override
  SchoolProfileDto version(num version) => this(version: version);

  @override
  SchoolProfileDto updatedAt(String updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SchoolProfileDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SchoolProfileDto(...).copyWith(id: 12, name: "My name")
  /// ````
  SchoolProfileDto call({
    Object? name = const $CopyWithPlaceholder(),
    Object? shortName = const $CopyWithPlaceholder(),
    Object? governingBody = const $CopyWithPlaceholder(),
    Object? address = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? principal = const $CopyWithPlaceholder(),
    Object? hasLogo = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return SchoolProfileDto(
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
      hasLogo: hasLogo == const $CopyWithPlaceholder()
          ? _value.hasLogo
          // ignore: cast_nullable_to_non_nullable
          : hasLogo as bool,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as num,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as String,
    );
  }
}

extension $SchoolProfileDtoCopyWith on SchoolProfileDto {
  /// Returns a callable class that can be used as follows: `instanceOfSchoolProfileDto.copyWith(...)` or like so:`instanceOfSchoolProfileDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SchoolProfileDtoCWProxy get copyWith => _$SchoolProfileDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolProfileDto _$SchoolProfileDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SchoolProfileDto', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'name',
          'shortName',
          'governingBody',
          'address',
          'phone',
          'email',
          'principal',
          'hasLogo',
          'version',
          'updatedAt',
        ],
      );
      final val = SchoolProfileDto(
        name: $checkedConvert('name', (v) => v as String),
        shortName: $checkedConvert('shortName', (v) => v as String),
        governingBody: $checkedConvert('governingBody', (v) => v as String?),
        address: $checkedConvert('address', (v) => v as String?),
        phone: $checkedConvert('phone', (v) => v as String?),
        email: $checkedConvert('email', (v) => v as String?),
        principal: $checkedConvert('principal', (v) => v as String?),
        hasLogo: $checkedConvert('hasLogo', (v) => v as bool),
        version: $checkedConvert('version', (v) => v as num),
        updatedAt: $checkedConvert('updatedAt', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SchoolProfileDtoToJson(SchoolProfileDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'shortName': instance.shortName,
      'governingBody': instance.governingBody,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'principal': instance.principal,
      'hasLogo': instance.hasLogo,
      'version': instance.version,
      'updatedAt': instance.updatedAt,
    };
