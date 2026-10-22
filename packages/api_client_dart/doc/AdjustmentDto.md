# api_client_dart.model.AdjustmentDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**gradebookId** | **num** |  |
**className** | **String** |  |
**subjectName** | **String** |  |
**termName** | **String** |  |
**status** | **String** |  |
**reason** | **String** |  |
**submittedBy** | [**AdjustmentPersonDto**](AdjustmentPersonDto.md) |  |
**submittedAt** | [**DateTime**](DateTime.md) |  |
**decidedBy** | [**AdjustmentPersonDto**](AdjustmentPersonDto.md) |  |
**decidedAt** | [**DateTime**](DateTime.md) |  |
**decisionReason** | **String** |  |
**lineCount** | **num** |  |
**version** | **num** |  |
**lines** | [**List&lt;AdjustmentLineDto&gt;**](AdjustmentLineDto.md) | Chỉ có trong chi tiết một phiếu | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
