# api_client_dart.model.FinalResultListDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**items** | [**List&lt;FinalResultDto&gt;**](FinalResultDto.md) |  |
**nextCursor** | **String** |  |
**exemptedStudents** | **num** | Số học sinh được miễn mọi ô của bảng (tính theo dữ liệu hiện tại, không theo cursor) |
**exempted** | [**List&lt;ExemptedStudentDto&gt;**](ExemptedStudentDto.md) |  |
**skippedStudents** | **num** | Số học sinh còn thiếu cột bắt buộc (tính theo dữ liệu hiện tại, không theo cursor) |
**skipped** | [**List&lt;SkippedStudentDto&gt;**](SkippedStudentDto.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
