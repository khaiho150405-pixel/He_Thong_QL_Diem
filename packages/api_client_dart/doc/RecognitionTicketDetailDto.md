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
**greenRows** | **num** | Số dòng mức Xanh (mức cuối) |
**yellowRows** | **num** | Số dòng mức Vàng (mức cuối) |
**redRows** | **num** | Số dòng mức Đỏ (mức cuối) |
**sourceImageUrl** | **String** |  |
**imageUrlExpiresInSeconds** | **num** |  |
**rows** | [**List&lt;RecognitionEvidenceRowDto&gt;**](RecognitionEvidenceRowDto.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
