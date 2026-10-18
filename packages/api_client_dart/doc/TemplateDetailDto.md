# api_client_dart.model.TemplateDetailDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **num** |  |
**name** | **String** |  |
**description** | **String** |  |
**status** | **String** |  |
**revision** | **num** | Số phiên bản của chuỗi mẫu |
**rootTemplateId** | **num** |  |
**columnCount** | **num** |  |
**gradeColumnCount** | **num** |  |
**version** | **num** | Dùng làm expectedVersion khi sửa/kích hoạt/ngừng |
**createdAt** | [**DateTime**](DateTime.md) |  |
**columns** | [**List&lt;TemplateColumnDto&gt;**](TemplateColumnDto.md) |  |
**imageUrl** | **String** | URL ký 300 giây của ảnh mẫu (kho lưu trữ private) |
**imageUrlExpiresInSeconds** | **num** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
