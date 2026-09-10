// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_dto.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProfileDtoCWProxy {
  ProfileDto name(String name);

  ProfileDto email(String? email);

  ProfileDto phone(String? phone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProfileDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProfileDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ProfileDto call({String name, String? email, String? phone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProfileDto.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProfileDto.copyWith.fieldName(...)`
class _$ProfileDtoCWProxyImpl implements _$ProfileDtoCWProxy {
  const _$ProfileDtoCWProxyImpl(this._value);

  final ProfileDto _value;

  @override
  ProfileDto name(String name) => this(name: name);

  @override
  ProfileDto email(String? email) => this(email: email);

  @override
  ProfileDto phone(String? phone) => this(phone: phone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProfileDto(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProfileDto(...).copyWith(id: 12, name: "My name")
  /// ````
  ProfileDto call({
    Object? name = const $CopyWithPlaceholder(),
    Object? email = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
  }) {
    return ProfileDto(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      email: email == const $CopyWithPlaceholder()
          ? _value.email
          // ignore: cast_nullable_to_non_nullable
          : email as String?,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
    );
  }
}

extension $ProfileDtoCopyWith on ProfileDto {
  /// Returns a callable class that can be used as follows: `instanceOfProfileDto.copyWith(...)` or like so:`instanceOfProfileDto.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProfileDtoCWProxy get copyWith => _$ProfileDtoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileDto _$ProfileDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProfileDto', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'email', 'phone']);
      final val = ProfileDto(
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String?),
        phone: $checkedConvert('phone', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ProfileDtoToJson(ProfileDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
    };
