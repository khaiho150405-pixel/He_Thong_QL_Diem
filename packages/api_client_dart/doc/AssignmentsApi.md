# api_client_dart.api.AssignmentsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**assignmentsCreate**](AssignmentsApi.md#assignmentscreate) | **POST** /api/v1/catalog/assignments |
[**assignmentsList**](AssignmentsApi.md#assignmentslist) | **GET** /api/v1/catalog/assignments |
[**assignmentsRemove**](AssignmentsApi.md#assignmentsremove) | **DELETE** /api/v1/catalog/assignments/{id} |
[**assignmentsUpdate**](AssignmentsApi.md#assignmentsupdate) | **PUT** /api/v1/catalog/assignments/{id} |


# **assignmentsCreate**
> AssignmentsDto assignmentsCreate(assignmentsInput)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAssignmentsApi();
final AssignmentsInput assignmentsInput = ; // AssignmentsInput |

try {
    final response = api.assignmentsCreate(assignmentsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AssignmentsApi->assignmentsCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **assignmentsInput** | [**AssignmentsInput**](AssignmentsInput.md)|  |

### Return type

[**AssignmentsDto**](AssignmentsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignmentsList**
> AssignmentsPage assignmentsList(q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAssignmentsApi();
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.assignmentsList(q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AssignmentsApi->assignmentsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**AssignmentsPage**](AssignmentsPage.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignmentsRemove**
> assignmentsRemove(id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAssignmentsApi();
final num id = 8.14; // num |

try {
    api.assignmentsRemove(id);
} catch on DioException (e) {
    print('Exception when calling AssignmentsApi->assignmentsRemove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

void (empty response body)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **assignmentsUpdate**
> AssignmentsDto assignmentsUpdate(id, assignmentsInput)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAssignmentsApi();
final num id = 8.14; // num |
final AssignmentsInput assignmentsInput = ; // AssignmentsInput |

try {
    final response = api.assignmentsUpdate(id, assignmentsInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AssignmentsApi->assignmentsUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **assignmentsInput** | [**AssignmentsInput**](AssignmentsInput.md)|  |

### Return type

[**AssignmentsDto**](AssignmentsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
