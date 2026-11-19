# api_client_dart.model.StudentSubjectResultDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**passFail** | **bool** |  | [optional]
**subjectName** | **String** |  |
**termName** | **String** |  |
**yearId** | **num** |  |
**yearName** | **String** |  |
**className** | **String** | Lớp của em trong học kỳ này (theo ghi danh) |
**components** | [**List&lt;StudentApprovedComponentDto&gt;**](StudentApprovedComponentDto.md) |  |
**finalScore** | **String** | Điểm tổng kết môn; null cho tới khi học kỳ được công bố |
**classification** | **String** | Xếp loại môn; null cho tới khi học kỳ được công bố |
**termAverage** | **String** | Điểm TB học kỳ (cùng nguồn với summary.averageScore); null khi chưa công bố |
**termClassification** | **String** | Xếp loại chung theo chính sách đang áp dụng; null khi chưa công bố |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
