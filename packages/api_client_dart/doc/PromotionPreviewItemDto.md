# api_client_dart.model.PromotionPreviewItemDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**studentId** | **num** |  |
**studentName** | **String** |  |
**order** | **num** | STT trong lớp nguồn |
**suggestedAction** | **String** |  |
**suggestedTargetClassId** | **num** | Lớp khối +1 cùng hậu tố (10A1 → 11A1); null nếu không có |
**alreadyEnrolledInTargetYear** | **bool** |  |
**processedStatus** | **String** | Trạng thái ghi danh nguồn nếu đã đóng; null nếu em còn DANG_HOC (chỉ dòng này mới gửi lên lớp được) |
**targetClassName** | **String** | Lớp ghi danh của em ở năm đích (nếu có) |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
