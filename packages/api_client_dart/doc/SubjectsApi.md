# api_client_dart.api.SubjectsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**subjectsCreate**](SubjectsApi.md#subjectscreate) | **POST** /api/v1/catalog/subjects |
[**subjectsList**](SubjectsApi.md#subjectslist) | **GET** /api/v1/catalog/subjects |
[**subjectsRemove**](SubjectsApi.md#subjectsremove) | **DELETE** /api/v1/catalog/subjects/{id} |
[**subjectsUpdate**](SubjectsApi.md#subjectsupdate) | **PUT** /api/v1/catalog/subjects/{id} |


# **subjectsCreate**
> SubjectsDto subjectsCreate(subjectsInput)



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

final api = ApiClientDart().getSubjectsApi();
final SubjectsInput subjectsInput = ; // SubjectsInput |

try {
    final response = api.subjectsCreate(subjectsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SubjectsApi->subjectsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subjectsInput** | [**SubjectsInput**](SubjectsInput.md)|  |

### Return type

[**SubjectsDto**](SubjectsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subjectsList**
> SubjectsPage subjectsList(q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getSubjectsApi();
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.subjectsList(q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SubjectsApi->subjectsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**SubjectsPage**](SubjectsPage.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subjectsRemove**
> subjectsRemove(id)



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

final api = ApiClientDart().getSubjectsApi();
final num id = 8.14; // num |

try {
    api.subjectsRemove(id);
} catch on DioException (e) {
    print('Exception when calling SubjectsApi->subjectsRemove: $e\n');
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

# **subjectsUpdate**
> SubjectsDto subjectsUpdate(id, subjectsInput)



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

final api = ApiClientDart().getSubjectsApi();
final num id = 8.14; // num |
final SubjectsInput subjectsInput = ; // SubjectsInput |

try {
    final response = api.subjectsUpdate(id, subjectsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SubjectsApi->subjectsUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **subjectsInput** | [**SubjectsInput**](SubjectsInput.md)|  |

### Return type

[**SubjectsDto**](SubjectsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
