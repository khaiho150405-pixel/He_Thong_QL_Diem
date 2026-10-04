# api_client_dart.api.SemesterWeightsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**semesterWeightsCreate**](SemesterWeightsApi.md#semesterweightscreate) | **POST** /api/v1/catalog/semester-weights |
[**semesterWeightsList**](SemesterWeightsApi.md#semesterweightslist) | **GET** /api/v1/catalog/semester-weights |
[**semesterWeightsRemove**](SemesterWeightsApi.md#semesterweightsremove) | **DELETE** /api/v1/catalog/semester-weights/{id} |
[**semesterWeightsUpdate**](SemesterWeightsApi.md#semesterweightsupdate) | **PUT** /api/v1/catalog/semester-weights/{id} |


# **semesterWeightsCreate**
> SemesterWeightsDto semesterWeightsCreate(semesterWeightsInput)



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

final api = ApiClientDart().getSemesterWeightsApi();
final SemesterWeightsInput semesterWeightsInput = ; // SemesterWeightsInput |

try {
    final response = api.semesterWeightsCreate(semesterWeightsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemesterWeightsApi->semesterWeightsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **semesterWeightsInput** | [**SemesterWeightsInput**](SemesterWeightsInput.md)|  |

### Return type

[**SemesterWeightsDto**](SemesterWeightsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semesterWeightsList**
> SemesterWeightsPage semesterWeightsList(q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getSemesterWeightsApi();
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.semesterWeightsList(q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemesterWeightsApi->semesterWeightsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**SemesterWeightsPage**](SemesterWeightsPage.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semesterWeightsRemove**
> semesterWeightsRemove(id)



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

final api = ApiClientDart().getSemesterWeightsApi();
final num id = 8.14; // num |

try {
    api.semesterWeightsRemove(id);
} catch on DioException (e) {
    print('Exception when calling SemesterWeightsApi->semesterWeightsRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

void (empty response body)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semesterWeightsUpdate**
> SemesterWeightsDto semesterWeightsUpdate(id, semesterWeightsInput)



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

final api = ApiClientDart().getSemesterWeightsApi();
final num id = 8.14; // num |
final SemesterWeightsInput semesterWeightsInput = ; // SemesterWeightsInput |

try {
    final response = api.semesterWeightsUpdate(id, semesterWeightsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemesterWeightsApi->semesterWeightsUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **semesterWeightsInput** | [**SemesterWeightsInput**](SemesterWeightsInput.md)|  |

### Return type

[**SemesterWeightsDto**](SemesterWeightsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
