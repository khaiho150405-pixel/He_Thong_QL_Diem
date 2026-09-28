//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_kpi_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminKpiDto {
  /// Returns a new [AdminKpiDto] instance.
  AdminKpiDto({
    required this.totalStudents,

    required this.totalClasses,

    required this.totalTeachers,

    required this.lockedGradebooks,

    required this.totalGradebooks,

    required this.completionRate,

    required this.pendingOcrTickets,
  });

  @JsonKey(name: r'totalStudents', required: true, includeIfNull: false)
  final num totalStudents;

  @JsonKey(name: r'totalClasses', required: true, includeIfNull: false)
  final num totalClasses;

  @JsonKey(name: r'totalTeachers', required: true, includeIfNull: false)
  final num totalTeachers;

  @JsonKey(name: r'lockedGradebooks', required: true, includeIfNull: false)
  final num lockedGradebooks;

  @JsonKey(name: r'totalGradebooks', required: true, includeIfNull: false)
  final num totalGradebooks;

  @JsonKey(name: r'completionRate', required: true, includeIfNull: false)
  final num completionRate;

  @JsonKey(name: r'pendingOcrTickets', required: true, includeIfNull: false)
  final num pendingOcrTickets;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminKpiDto &&
          other.totalStudents == totalStudents &&
          other.totalClasses == totalClasses &&
          other.totalTeachers == totalTeachers &&
          other.lockedGradebooks == lockedGradebooks &&
          other.totalGradebooks == totalGradebooks &&
          other.completionRate == completionRate &&
          other.pendingOcrTickets == pendingOcrTickets;

  @override
  int get hashCode =>
      totalStudents.hashCode +
      totalClasses.hashCode +
      totalTeachers.hashCode +
      lockedGradebooks.hashCode +
      totalGradebooks.hashCode +
      completionRate.hashCode +
      pendingOcrTickets.hashCode;

  factory AdminKpiDto.fromJson(Map<String, dynamic> json) =>
      _$AdminKpiDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AdminKpiDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
