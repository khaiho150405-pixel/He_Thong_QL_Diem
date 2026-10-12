# api_client_dart.model.RecognitionTicketDetailDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ticketId** | **String** |  |
**gradebookId** | **num** |  |
**componentId** | **num** |  |
**componentName** | **String** |  |
**declaredRows** | **num** |  |
**detectedRows** | **num** |  |
**status** | **String** |  |
**errorCode** | **String** |  |
**modelVersion** | **String** |  |
**version** | **num** |  |
**createdAt** | [**DateTime**](DateTime.md) |  |
**cancelReason** | **String** | Lý do hủy phiếu; null khi phiếu chưa hủy |
**cancelledAt** | [**DateTime**](DateTime.md) | Thời điểm hủy phiếu; null khi phiếu chưa hủy |
**greenRows** | **num** | Số dòng mức Xanh (mức cuối) |
**yellowRows** | **num** | Số dòng mức Vàng (mức cuối) |
**redRows** | **num** | Số dòng mức Đỏ (mức cuối) |
**sourceImageUrl** | **String** | URL ký 300 giây của ảnh gốc; chuỗi rỗng khi phiếu đã hủy (ảnh đã bị xóa khỏi kho lưu trữ) |
**imageUrlExpiresInSeconds** | **num** |  |
**rows** | [**List&lt;RecognitionEvidenceRowDto&gt;**](RecognitionEvidenceRowDto.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
