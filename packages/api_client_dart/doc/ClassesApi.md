# api_client_dart.api.ClassesApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**classesCreate**](ClassesApi.md#classescreate) | **POST** /api/v1/catalog/classes |
[**classesList**](ClassesApi.md#classeslist) | **GET** /api/v1/catalog/classes |
[**classesRemove**](ClassesApi.md#classesremove) | **DELETE** /api/v1/catalog/classes/{id} |
[**classesUpdate**](ClassesApi.md#classesupdate) | **PUT** /api/v1/catalog/classes/{id} |


# **classesCreate**
> ClassesDto classesCreate(classesInput)



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

final api = ApiClientDart().getClassesApi();
final ClassesInput classesInput = ; // ClassesInput |

try {
    final response = api.classesCreate(classesInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ClassesApi->classesCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **classesInput** | [**ClassesInput**](ClassesInput.md)|  |

### Return type

[**ClassesDto**](ClassesDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **classesList**
> ClassesPage classesList(q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getClassesApi();
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.classesList(q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ClassesApi->classesList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**ClassesPage**](ClassesPage.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **classesRemove**
> classesRemove(id)



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

final api = ApiClientDart().getClassesApi();
final num id = 8.14; // num |

try {
    api.classesRemove(id);
} catch on DioException (e) {
    print('Exception when calling ClassesApi->classesRemove: $e\n');
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

# **classesUpdate**
> ClassesDto classesUpdate(id, classesInput)



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

final api = ApiClientDart().getClassesApi();
final num id = 8.14; // num |
final ClassesInput classesInput = ; // ClassesInput |

try {
    final response = api.classesUpdate(id, classesInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ClassesApi->classesUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **classesInput** | [**ClassesInput**](ClassesInput.md)|  |

### Return type

[**ClassesDto**](ClassesDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
