# api_client_dart.model.RecognitionEvidenceRowDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**rowId** | **String** |  |
**order** | **num** | Vị trí dòng trên ảnh |
**stt** | **num** | STT hệ thống trong danh sách lớp đã chốt của phiếu |
**sttOnPaper** | **num** | STT in trên giấy đọc được |
**studentId** | **num** |  |
**studentName** | **String** | Họ tên học sinh theo danh sách lớp đã chốt |
**nameRead** | **String** | Họ tên máy đọc được trên giấy |
**matchConfidence** | **String** | Độ tin cậy ghép dòng với học sinh, 0..1 |
**matchNote** | **String** |  |
**numericRaw** | **String** |  |
**numericValue** | **String** |  |
**numericConfidence** | **String** |  |
**writtenRaw** | **String** |  |
**writtenValue** | **String** |  |
**writtenConfidence** | **String** |  |
**comparison** | **String** |  |
**reviewLevel** | **String** |  |
**finalValue** | **String** |  |
**numericCropUrl** | **String** |  |
**writtenCropUrl** | **String** |  |
**nameCropUrl** | **String** | Ảnh ô họ tên trên giấy (URL ký 300 giây) |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
