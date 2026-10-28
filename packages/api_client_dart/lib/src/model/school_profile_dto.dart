//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school_profile_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolProfileDto {
  /// Returns a new [SchoolProfileDto] instance.
  SchoolProfileDto({
    required this.name,

    required this.shortName,

    required this.governingBody,

    required this.address,

    required this.phone,

    required this.email,

    required this.principal,

    required this.hasLogo,

    required this.version,

    required this.updatedAt,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'shortName', required: true, includeIfNull: false)
  final String shortName;

  @JsonKey(name: r'governingBody', required: true, includeIfNull: true)
  final String? governingBody;

  @JsonKey(name: r'address', required: true, includeIfNull: true)
  final String? address;

  @JsonKey(name: r'phone', required: true, includeIfNull: true)
  final String? phone;

  @JsonKey(name: r'email', required: true, includeIfNull: true)
  final String? email;

  @JsonKey(name: r'principal', required: true, includeIfNull: true)
  final String? principal;

  @JsonKey(name: r'hasLogo', required: true, includeIfNull: false)
  final bool hasLogo;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  @JsonKey(name: r'updatedAt', required: true, includeIfNull: false)
  final String updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolProfileDto &&
          other.name == name &&
          other.shortName == shortName &&
          other.governingBody == governingBody &&
          other.address == address &&
          other.phone == phone &&
          other.email == email &&
          other.principal == principal &&
          other.hasLogo == hasLogo &&
          other.version == version &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      name.hashCode +
      shortName.hashCode +
      (governingBody == null ? 0 : governingBody.hashCode) +
      (address == null ? 0 : address.hashCode) +
      (phone == null ? 0 : phone.hashCode) +
      (email == null ? 0 : email.hashCode) +
      (principal == null ? 0 : principal.hashCode) +
      hasLogo.hashCode +
      version.hashCode +
      updatedAt.hashCode;

  factory SchoolProfileDto.fromJson(Map<String, dynamic> json) =>
      _$SchoolProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolProfileDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
