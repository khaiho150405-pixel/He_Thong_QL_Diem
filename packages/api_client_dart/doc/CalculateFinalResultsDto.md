# api_client_dart.model.CalculateFinalResultsDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**gradebookId** | **num** |  |
**gradebookVersion** | **num** |  |
**weightVersion** | **String** |  |
**policyVersion** | **String** |  |
**calculatedStudents** | **num** |  |
**skippedStudents** | **num** |  |
**results** | [**List&lt;FinalResultDto&gt;**](FinalResultDto.md) |  |
**skipped** | [**List&lt;SkippedStudentDto&gt;**](SkippedStudentDto.md) |  |
**exemptedStudents** | **num** | Học sinh được miễn mọi ô của bảng: không tạo kết quả |
**exempted** | [**List&lt;ExemptedStudentDto&gt;**](ExemptedStudentDto.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
