//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client_dart/src/model/initialized_gradebook_dto.dart';
import 'package:api_client_dart/src/model/skipped_gradebook_dto.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'initialize_gradebooks_result_dto.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InitializeGradebooksResultDto {
  /// Returns a new [InitializeGradebooksResultDto] instance.
  InitializeGradebooksResultDto({required this.created, required this.skipped});

  @JsonKey(name: r'created', required: true, includeIfNull: false)
  final List<InitializedGradebookDto> created;

  @JsonKey(name: r'skipped', required: true, includeIfNull: false)
  final List<SkippedGradebookDto> skipped;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InitializeGradebooksResultDto &&
          other.created == created &&
          other.skipped == skipped;

  @override
  int get hashCode => created.hashCode + skipped.hashCode;

  factory InitializeGradebooksResultDto.fromJson(Map<String, dynamic> json) =>
      _$InitializeGradebooksResultDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InitializeGradebooksResultDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
