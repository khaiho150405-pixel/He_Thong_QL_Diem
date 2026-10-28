//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'timetable_semester_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TimetableSemesterDto {
  /// Returns a new [TimetableSemesterDto] instance.
  TimetableSemesterDto({
    required this.id,

    required this.name,

    required this.yearName,

    required this.startDate,

    required this.endDate,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final num id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'yearName', required: true, includeIfNull: false)
  final String yearName;

  /// YYYY-MM-DD
  @JsonKey(name: r'startDate', required: true, includeIfNull: false)
  final String startDate;

  /// YYYY-MM-DD
  @JsonKey(name: r'endDate', required: true, includeIfNull: false)
  final String endDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableSemesterDto &&
          other.id == id &&
          other.name == name &&
          other.yearName == yearName &&
          other.startDate == startDate &&
          other.endDate == endDate;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      yearName.hashCode +
      startDate.hashCode +
      endDate.hashCode;

  factory TimetableSemesterDto.fromJson(Map<String, dynamic> json) =>
      _$TimetableSemesterDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TimetableSemesterDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
