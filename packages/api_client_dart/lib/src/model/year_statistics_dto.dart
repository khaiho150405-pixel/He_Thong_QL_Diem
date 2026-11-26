//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/statistics_group_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'year_statistics_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class YearStatisticsDto {
  /// Returns a new [YearStatisticsDto] instance.
  YearStatisticsDto({
    required this.yearId,

    required this.yearName,

    required this.source_,

    required this.snapshotVersion,

    required this.snapshotAt,

    required this.total,

    required this.grades,

    required this.classes,

    required this.subjects,
  });

  @JsonKey(name: r'yearId', required: true, includeIfNull: false)
  final num yearId;

  @JsonKey(name: r'yearName', required: true, includeIfNull: false)
  final String yearName;

  /// BAN_CHOT hoặc HIEN_TAI
  @JsonKey(name: r'source', required: true, includeIfNull: false)
  final String source_;

  @JsonKey(name: r'snapshotVersion', required: true, includeIfNull: true)
  final num? snapshotVersion;

  @JsonKey(name: r'snapshotAt', required: true, includeIfNull: true)
  final String? snapshotAt;

  @JsonKey(name: r'total', required: true, includeIfNull: true)
  final StatisticsGroupDto? total;

  @JsonKey(name: r'grades', required: true, includeIfNull: false)
  final List<StatisticsGroupDto> grades;

  @JsonKey(name: r'classes', required: true, includeIfNull: false)
  final List<StatisticsGroupDto> classes;

  @JsonKey(name: r'subjects', required: true, includeIfNull: false)
  final List<StatisticsGroupDto> subjects;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YearStatisticsDto &&
          other.yearId == yearId &&
          other.yearName == yearName &&
          other.source_ == source_ &&
          other.snapshotVersion == snapshotVersion &&
          other.snapshotAt == snapshotAt &&
          other.total == total &&
          other.grades == grades &&
          other.classes == classes &&
          other.subjects == subjects;

  @override
  int get hashCode =>
      yearId.hashCode +
      yearName.hashCode +
      source_.hashCode +
      (snapshotVersion == null ? 0 : snapshotVersion.hashCode) +
      (snapshotAt == null ? 0 : snapshotAt.hashCode) +
      (total == null ? 0 : total.hashCode) +
      grades.hashCode +
      classes.hashCode +
      subjects.hashCode;

  factory YearStatisticsDto.fromJson(Map<String, dynamic> json) =>
      _$YearStatisticsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$YearStatisticsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
