//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/semester_deadline_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semester_deadlines_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemesterDeadlinesDto {
  /// Returns a new [SemesterDeadlinesDto] instance.
  SemesterDeadlinesDto({required this.items});

  /// Luôn 3 phần tử theo thứ tự TX, GK, CK
  @JsonKey(name: r'items', required: true, includeIfNull: false)
  final List<SemesterDeadlineDto> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterDeadlinesDto && other.items == items;

  @override
  int get hashCode => items.hashCode;

  factory SemesterDeadlinesDto.fromJson(Map<String, dynamic> json) =>
      _$SemesterDeadlinesDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SemesterDeadlinesDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
