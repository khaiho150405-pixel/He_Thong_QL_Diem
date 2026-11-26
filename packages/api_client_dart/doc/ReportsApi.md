# api_client_dart.api.ReportsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adminReportsOverview**](ReportsApi.md#adminreportsoverview) | **GET** /api/v1/reports/admin/overview |
[**reportsExport**](ReportsApi.md#reportsexport) | **GET** /api/v1/reports/gradebooks/{gradebookId}/export.xlsx |
[**reportsSummary**](ReportsApi.md#reportssummary) | **GET** /api/v1/reports/gradebooks/{gradebookId}/summary |
[**yearReportsComparison**](ReportsApi.md#yearreportscomparison) | **GET** /api/v1/reports/admin/years/comparison |
[**yearReportsExport**](ReportsApi.md#yearreportsexport) | **GET** /api/v1/reports/admin/years/{yearId}/export.xlsx |
[**yearReportsStatistics**](ReportsApi.md#yearreportsstatistics) | **GET** /api/v1/reports/admin/years/{yearId}/statistics |


# **adminReportsOverview**
> AdminOverviewDto adminReportsOverview(yearId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getReportsApi();
final num yearId = 8.14; // num | Chỉ thống kê một năm học; vắng = mọi năm

try {
    final response = api.adminReportsOverview(yearId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->adminReportsOverview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **yearId** | **num**| Chỉ thống kê một năm học; vắng = mọi năm | [optional]

### Return type

[**AdminOverviewDto**](AdminOverviewDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **yearReportsComparison**
> YearComparisonDto yearReportsComparison(term)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getReportsApi();
final num term = 8.14; // num | Thứ tự học kỳ: 1, 2 hoặc 3

try {
    final response = api.yearReportsComparison(term);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->yearReportsComparison: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **term** | **num**| Thứ tự học kỳ: 1, 2 hoặc 3 |

### Return type

[**YearComparisonDto**](YearComparisonDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **yearReportsExport**
> Uint8List yearReportsExport(term, yearId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getReportsApi();
final num term = 8.14; // num | Thứ tự học kỳ: 1, 2 hoặc 3
final num yearId = 8.14; // num |

try {
    final response = api.yearReportsExport(term, yearId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->yearReportsExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **term** | **num**| Thứ tự học kỳ: 1, 2 hoặc 3 |
 **yearId** | **num**|  |

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **yearReportsStatistics**
> YearStatisticsDto yearReportsStatistics(term, yearId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getReportsApi();
final num term = 8.14; // num | Thứ tự học kỳ: 1, 2 hoặc 3
final num yearId = 8.14; // num |

try {
    final response = api.yearReportsStatistics(term, yearId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReportsApi->yearReportsStatistics: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **term** | **num**| Thứ tự học kỳ: 1, 2 hoặc 3 |
 **yearId** | **num**|  |

### Return type

[**YearStatisticsDto**](YearStatisticsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
