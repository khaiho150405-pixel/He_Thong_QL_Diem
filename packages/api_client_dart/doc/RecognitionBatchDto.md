# api_client_dart.model.RecognitionBatchDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**batchId** | **String** |  |
**gradebookId** | **num** |  |
**templateId** | **num** |  |
**pageCount** | **num** |  |
**status** | **String** |  |
**errorCode** | **String** | Mã lỗi chung của lô; mọi phiếu LOI của lô mang cùng mã |
**errorPage** | **num** | Trang gây lỗi (1..pageCount); null khi lỗi không gắn với trang |
**modelVersion** | **String** |  |
**version** | **num** |  |
**createdAt** | [**DateTime**](DateTime.md) |  |
**cancelReason** | **String** |  |
**cancelledAt** | [**DateTime**](DateTime.md) |  |
**imageUrlExpiresInSeconds** | **num** |  |
**pages** | [**List&lt;RecognitionBatchPageDto&gt;**](RecognitionBatchPageDto.md) |  |
**tickets** | [**List&lt;RecognitionBatchTicketDto&gt;**](RecognitionBatchTicketDto.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
