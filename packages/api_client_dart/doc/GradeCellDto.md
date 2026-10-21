# api_client_dart.model.GradeCellDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**studentId** | **num** |  |
**studentName** | **String** |  |
**stt** | **num** | STT trong lớp theo thứ tự tên; null khi học sinh đã nghỉ |
**active** | **bool** |  |
**componentId** | **num** |  |
**componentName** | **String** |  |
**coefficient** | **String** |  |
**required_** | **bool** |  |
**displayOrder** | **num** |  |
**openForInput** | **bool** |  | [optional]
**columnLocked** | **bool** |  | [optional]
**passFail** | **bool** |  | [optional]
**opensAt** | **String** |  | [optional]
**closesAt** | **String** |  | [optional]
**deadlineVersion** | **num** |  | [optional]
**deadlineSource** | **String** | Nguồn lịch hiệu lực: RIENG (bảng + cột) ghi đè HOC_KY (mặc định theo loại điểm); null = chưa có lịch | [optional]
**value** | **String** |  |
**status** | **String** | MIEN: ô được miễn (giá trị luôn null, khác chưa có điểm) |
**source_** | **String** |  |
**exemptionReason** | **String** | Lý do miễn gần nhất khi status = MIEN, ngược lại null |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
