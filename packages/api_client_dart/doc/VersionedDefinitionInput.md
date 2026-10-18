# api_client_dart.model.VersionedDefinitionInput

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**name** | **String** |  |
**description** | **String** |  | [optional]
**columns** | [**List&lt;TemplateColumnDto&gt;**](TemplateColumnDto.md) | Mọi cột 0..n-1 của tờ mẫu (cột không đọc dùng BO_QUA). Đúng một HO_TEN, tối đa một STT, ít nhất một DIEM; cặp (group, order) không trùng; mỗi DIEM_CHU trỏ tới một DIEM bằng pairedWith. |
**expectedVersion** | **num** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
