//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'level_counts_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LevelCountsDto {
  /// Returns a new [LevelCountsDto] instance.
  LevelCountsDto({
    required this.TOT,

    required this.KHA,

    required this.DAT,

    required this.CHUA_DAT,

    required this.CHUA_DU_MON,
  });

  @JsonKey(name: r'TOT', required: true, includeIfNull: false)
  final num TOT;

  @JsonKey(name: r'KHA', required: true, includeIfNull: false)
  final num KHA;

  @JsonKey(name: r'DAT', required: true, includeIfNull: false)
  final num DAT;

  @JsonKey(name: r'CHUA_DAT', required: true, includeIfNull: false)
  final num CHUA_DAT;

  @JsonKey(name: r'CHUA_DU_MON', required: true, includeIfNull: false)
  final num CHUA_DU_MON;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelCountsDto &&
          other.TOT == TOT &&
          other.KHA == KHA &&
          other.DAT == DAT &&
          other.CHUA_DAT == CHUA_DAT &&
          other.CHUA_DU_MON == CHUA_DU_MON;

  @override
  int get hashCode =>
      TOT.hashCode +
      KHA.hashCode +
      DAT.hashCode +
      CHUA_DAT.hashCode +
      CHUA_DU_MON.hashCode;

  factory LevelCountsDto.fromJson(Map<String, dynamic> json) =>
      _$LevelCountsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LevelCountsDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
