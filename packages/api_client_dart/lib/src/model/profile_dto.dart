//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProfileDto {
  /// Returns a new [ProfileDto] instance.
  ProfileDto({required this.name, required this.email, required this.phone});

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'email', required: true, includeIfNull: true)
  final String? email;

  @JsonKey(name: r'phone', required: true, includeIfNull: true)
  final String? phone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileDto &&
          other.name == name &&
          other.email == email &&
          other.phone == phone;

  @override
  int get hashCode =>
      name.hashCode +
      (email == null ? 0 : email.hashCode) +
      (phone == null ? 0 : phone.hashCode);

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
