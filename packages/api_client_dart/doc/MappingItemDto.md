# api_client_dart.model.MappingItemDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**templateColumnIndex** | **num** | Chỉ số cột điểm trong mẫu |
**key** | **String** | Định danh cột điểm, ví dụ TX1 |
**group** | **String** |  |
**order** | **num** | Thứ tự trong nhóm, từ 1 |
**channels** | **String** | SO = chỉ điểm số (tối đa Vàng); SO_CHU = đọc cả điểm số lẫn điểm chữ |
**componentId** | **num** | Thành phần điểm của môn khớp (nhóm, thứ tự); null khi môn không có thành phần tương ứng |
**componentName** | **String** |  |
**locked** | **bool** | Cột đã chốt, ngoài thời gian nhập, bảng đã chốt hoặc môn Đạt/Không đạt: không chọn được |
**pending** | **bool** | Đang có phiếu chờ xử lý/đối chiếu: không chọn được |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
