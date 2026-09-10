# api_client_dart.api.ComponentsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**componentsCreate**](ComponentsApi.md#componentscreate) | **POST** /api/v1/catalog/components |
[**componentsList**](ComponentsApi.md#componentslist) | **GET** /api/v1/catalog/components |
[**componentsRemove**](ComponentsApi.md#componentsremove) | **DELETE** /api/v1/catalog/components/{id} |
[**componentsUpdate**](ComponentsApi.md#componentsupdate) | **PUT** /api/v1/catalog/components/{id} |


# **componentsCreate**
> ComponentsDto componentsCreate(componentsInput)



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

final api = ApiClientDart().getComponentsApi();
final ComponentsInput componentsInput = ; // ComponentsInput |

try {
    final response = api.componentsCreate(componentsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ComponentsApi->componentsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **componentsInput** | [**ComponentsInput**](ComponentsInput.md)|  |

### Return type

[**ComponentsDto**](ComponentsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **componentsList**
> ComponentsPage componentsList(q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getComponentsApi();
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.componentsList(q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ComponentsApi->componentsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**ComponentsPage**](ComponentsPage.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **componentsRemove**
> componentsRemove(id)



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

final api = ApiClientDart().getComponentsApi();
final num id = 8.14; // num |

try {
    api.componentsRemove(id);
} catch on DioException (e) {
    print('Exception when calling ComponentsApi->componentsRemove: $e\n');
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

# **componentsUpdate**
> ComponentsDto componentsUpdate(id, componentsInput)



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

final api = ApiClientDart().getComponentsApi();
final num id = 8.14; // num |
final ComponentsInput componentsInput = ; // ComponentsInput |

try {
    final response = api.componentsUpdate(id, componentsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ComponentsApi->componentsUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **componentsInput** | [**ComponentsInput**](ComponentsInput.md)|  |

### Return type

[**ComponentsDto**](ComponentsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
