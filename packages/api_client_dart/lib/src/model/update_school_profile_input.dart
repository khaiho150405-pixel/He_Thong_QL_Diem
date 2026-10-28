//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_school_profile_input.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateSchoolProfileInput {
  /// Returns a new [UpdateSchoolProfileInput] instance.
  UpdateSchoolProfileInput({
    required this.expectedVersion,

    required this.name,

    required this.shortName,

    this.governingBody,

    this.address,

    this.phone,

    this.email,

    this.principal,
  });

  // minimum: 1
  @JsonKey(name: r'expectedVersion', required: true, includeIfNull: false)
  final num expectedVersion;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'shortName', required: true, includeIfNull: false)
  final String shortName;

  @JsonKey(name: r'governingBody', required: false, includeIfNull: false)
  final String? governingBody;

  @JsonKey(name: r'address', required: false, includeIfNull: false)
  final String? address;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  @JsonKey(name: r'email', required: false, includeIfNull: false)
  final String? email;

  @JsonKey(name: r'principal', required: false, includeIfNull: false)
  final String? principal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateSchoolProfileInput &&
          other.expectedVersion == expectedVersion &&
          other.name == name &&
          other.shortName == shortName &&
          other.governingBody == governingBody &&
          other.address == address &&
          other.phone == phone &&
          other.email == email &&
          other.principal == principal;

  @override
  int get hashCode =>
      expectedVersion.hashCode +
      name.hashCode +
      shortName.hashCode +
      (governingBody == null ? 0 : governingBody.hashCode) +
      (address == null ? 0 : address.hashCode) +
      (phone == null ? 0 : phone.hashCode) +
      (email == null ? 0 : email.hashCode) +
      (principal == null ? 0 : principal.hashCode);

  factory UpdateSchoolProfileInput.fromJson(Map<String, dynamic> json) =>
      _$UpdateSchoolProfileInputFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateSchoolProfileInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
