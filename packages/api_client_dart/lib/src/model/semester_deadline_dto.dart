//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'semester_deadline_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SemesterDeadlineDto {
  /// Returns a new [SemesterDeadlineDto] instance.
  SemesterDeadlineDto({
    required this.type,

    required this.opensAt,

    required this.closesAt,

    required this.version,

    required this.expired,
  });

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final SemesterDeadlineDtoTypeEnum type;

  @JsonKey(name: r'opensAt', required: true, includeIfNull: true)
  final DateTime? opensAt;

  @JsonKey(name: r'closesAt', required: true, includeIfNull: true)
  final DateTime? closesAt;

  /// 0 khi học kỳ chưa đặt lịch cho loại điểm này
  // minimum: 0
  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final num version;

  /// Đã qua hạn đóng
  @JsonKey(name: r'expired', required: true, includeIfNull: false)
  final bool expired;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterDeadlineDto &&
          other.type == type &&
          other.opensAt == opensAt &&
          other.closesAt == closesAt &&
          other.version == version &&
          other.expired == expired;

  @override
  int get hashCode =>
      type.hashCode +
      (opensAt == null ? 0 : opensAt.hashCode) +
      (closesAt == null ? 0 : closesAt.hashCode) +
      version.hashCode +
      expired.hashCode;

  factory SemesterDeadlineDto.fromJson(Map<String, dynamic> json) =>
      _$SemesterDeadlineDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SemesterDeadlineDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

enum SemesterDeadlineDtoTypeEnum {
  @JsonValue(r'TX')
  TX(r'TX'),
  @JsonValue(r'GK')
  GK(r'GK'),
  @JsonValue(r'CK')
  CK(r'CK');

  const SemesterDeadlineDtoTypeEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
