# api_client_dart.model.YearStatisticsDto

## Load the model package
```dart
import 'package:api_client_dart/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**yearId** | **num** |  |
**yearName** | **String** |  |
**source_** | **String** | BAN_CHOT hoặc HIEN_TAI |
**snapshotVersion** | **num** |  |
**snapshotAt** | **String** |  |
**total** | [**StatisticsGroupDto**](StatisticsGroupDto.md) |  |
**grades** | [**List&lt;StatisticsGroupDto&gt;**](StatisticsGroupDto.md) |  |
**classes** | [**List&lt;StatisticsGroupDto&gt;**](StatisticsGroupDto.md) |  |
**subjects** | [**List&lt;StatisticsGroupDto&gt;**](StatisticsGroupDto.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
