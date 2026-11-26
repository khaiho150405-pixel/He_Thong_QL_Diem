//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/level_counts_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'statistics_group_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StatisticsGroupDto {
  /// Returns a new [StatisticsGroupDto] instance.
  StatisticsGroupDto({
    required this.key,

    required this.label,

    required this.students,

    required this.average,

    required this.fromEight,

    required this.fromSixHalf,

    required this.fromFive,

    required this.belowFive,

    required this.passed,

    required this.failed,

    required this.missing,

    required this.levels,
  });

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final num key;

  @JsonKey(name: r'label', required: true, includeIfNull: false)
  final String label;

  @JsonKey(name: r'students', required: true, includeIfNull: false)
  final num students;

  /// Trung bình các điểm tổng kết môn tính điểm
  @JsonKey(name: r'average', required: true, includeIfNull: true)
  final String? average;

  @JsonKey(name: r'fromEight', required: true, includeIfNull: false)
  final num fromEight;

  @JsonKey(name: r'fromSixHalf', required: true, includeIfNull: false)
  final num fromSixHalf;

  @JsonKey(name: r'fromFive', required: true, includeIfNull: false)
  final num fromFive;

  @JsonKey(name: r'belowFive', required: true, includeIfNull: false)
  final num belowFive;

  @JsonKey(name: r'passed', required: true, includeIfNull: false)
  final num passed;

  @JsonKey(name: r'failed', required: true, includeIfNull: false)
  final num failed;

  /// Lượt môn chưa có điểm tổng kết
  @JsonKey(name: r'missing', required: true, includeIfNull: false)
  final num missing;

  /// null ở nhóm theo môn
  @JsonKey(name: r'levels', required: true, includeIfNull: true)
  final LevelCountsDto? levels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsGroupDto &&
          other.key == key &&
          other.label == label &&
          other.students == students &&
          other.average == average &&
          other.fromEight == fromEight &&
          other.fromSixHalf == fromSixHalf &&
          other.fromFive == fromFive &&
          other.belowFive == belowFive &&
          other.passed == passed &&
          other.failed == failed &&
          other.missing == missing &&
          other.levels == levels;

  @override
  int get hashCode =>
      key.hashCode +
      label.hashCode +
      students.hashCode +
      (average == null ? 0 : average.hashCode) +
      fromEight.hashCode +
      fromSixHalf.hashCode +
      fromFive.hashCode +
      belowFive.hashCode +
      passed.hashCode +
      failed.hashCode +
      missing.hashCode +
      (levels == null ? 0 : levels.hashCode);

  factory StatisticsGroupDto.fromJson(Map<String, dynamic> json) =>
      _$StatisticsGroupDtoFromJson(json);

  Map<String, dynamic> toJson() => _$StatisticsGroupDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
