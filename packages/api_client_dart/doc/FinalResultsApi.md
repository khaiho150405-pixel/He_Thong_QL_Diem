# api_client_dart.api.FinalResultsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**finalResultsCalculate**](FinalResultsApi.md#finalresultscalculate) | **POST** /api/v1/gradebooks/{gradebookId}/final-results/calculate |
[**finalResultsHistory**](FinalResultsApi.md#finalresultshistory) | **GET** /api/v1/gradebooks/{gradebookId}/final-results/{resultId}/history |
[**finalResultsList**](FinalResultsApi.md#finalresultslist) | **GET** /api/v1/gradebooks/{gradebookId}/final-results |


# **finalResultsCalculate**
> CalculateFinalResultsDto finalResultsCalculate(xIdempotencyKey, gradebookId, calculateFinalResultsInput)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';
// TODO Configure API key authorization: csrf
//defaultApiClient.getAuthentication<ApiKeyAuth>('csrf').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('csrf').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getFinalResultsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num gradebookId = 8.14; // num |
final CalculateFinalResultsInput calculateFinalResultsInput = ; // CalculateFinalResultsInput |

try {
    final response = api.finalResultsCalculate(xIdempotencyKey, gradebookId, calculateFinalResultsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FinalResultsApi->finalResultsCalculate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **gradebookId** | **num**|  |
 **calculateFinalResultsInput** | [**CalculateFinalResultsInput**](CalculateFinalResultsInput.md)|  |

### Return type

[**CalculateFinalResultsDto**](CalculateFinalResultsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finalResultsHistory**
> CalculationHistoryListDto finalResultsHistory(resultId, gradebookId, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getFinalResultsApi();
final String resultId = resultId_example; // String |
final num gradebookId = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.finalResultsHistory(resultId, gradebookId, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FinalResultsApi->finalResultsHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **resultId** | **String**|  |
 **gradebookId** | **num**|  |
 **cursor** | **String**|  | [optional]

### Return type

[**CalculationHistoryListDto**](CalculationHistoryListDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finalResultsList**
> FinalResultListDto finalResultsList(gradebookId, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getFinalResultsApi();
final num gradebookId = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.finalResultsList(gradebookId, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FinalResultsApi->finalResultsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gradebookId** | **num**|  |
 **cursor** | **String**|  | [optional]

### Return type

[**FinalResultListDto**](FinalResultListDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
