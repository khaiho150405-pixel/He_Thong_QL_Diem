# api_client_dart.api.ReportsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reportsExport**](ReportsApi.md#reportsexport) | **GET** /api/v1/reports/gradebooks/{gradebookId}/export.xlsx |
[**reportsSummary**](ReportsApi.md#reportssummary) | **GET** /api/v1/reports/gradebooks/{gradebookId}/summary |


# **reportsExport**
> Uint8List reportsExport(gradebookId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getReportsApi();
final num gradebookId = 8.14; // num |

try {
    final response = api.reportsExport(gradebookId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->reportsExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gradebookId** | **num**|  |

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reportsSummary**
> GradebookSummaryDto reportsSummary(gradebookId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getReportsApi();
final num gradebookId = 8.14; // num |

try {
    final response = api.reportsSummary(gradebookId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->reportsSummary: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gradebookId** | **num**|  |

### Return type

[**GradebookSummaryDto**](GradebookSummaryDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
