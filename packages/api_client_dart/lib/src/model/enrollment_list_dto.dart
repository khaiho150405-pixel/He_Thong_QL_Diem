//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/enrollment_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enrollment_list_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EnrollmentListDto {
  /// Returns a new [EnrollmentListDto] instance.
  EnrollmentListDto({required this.items});

  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<EnrollmentDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentListDto && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory EnrollmentListDto.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentListDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollmentListDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
