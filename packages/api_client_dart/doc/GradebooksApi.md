# api_client_dart.api.GradebooksApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**gradebooksBatchUpdate**](GradebooksApi.md#gradebooksbatchupdate) | **PUT** /api/v1/gradebooks/{id}/grades |
[**gradebooksCells**](GradebooksApi.md#gradebookscells) | **GET** /api/v1/gradebooks/{id}/cells |
[**gradebooksCreate**](GradebooksApi.md#gradebookscreate) | **POST** /api/v1/gradebooks |
[**gradebooksHistory**](GradebooksApi.md#gradebookshistory) | **GET** /api/v1/gradebooks/{id}/cells/{cellId}/history |
[**gradebooksList**](GradebooksApi.md#gradebookslist) | **GET** /api/v1/gradebooks |
[**gradebooksLock**](GradebooksApi.md#gradebookslock) | **POST** /api/v1/gradebooks/{id}/lock |
[**gradebooksSyncRoster**](GradebooksApi.md#gradebookssyncroster) | **POST** /api/v1/gradebooks/{id}/sync-roster |


# **gradebooksBatchUpdate**
> BatchUpdateResultDto gradebooksBatchUpdate(xIdempotencyKey, id, batchUpdateInput)



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

final api = ApiClientDart().getGradebooksApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final BatchUpdateInput batchUpdateInput = ; // BatchUpdateInput |

try {
    final response = api.gradebooksBatchUpdate(xIdempotencyKey, id, batchUpdateInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksBatchUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **batchUpdateInput** | [**BatchUpdateInput**](BatchUpdateInput.md)|  |

### Return type

[**BatchUpdateResultDto**](BatchUpdateResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebooksCells**
> CellsResponseDto gradebooksCells(id, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getGradebooksApi();
final num id = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.gradebooksCells(id, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksCells: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **cursor** | **String**|  | [optional]

### Return type

[**CellsResponseDto**](CellsResponseDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebooksCreate**
> GradebookDto gradebooksCreate(createGradebookInput)



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

final api = ApiClientDart().getGradebooksApi();
final CreateGradebookInput createGradebookInput = ; // CreateGradebookInput |

try {
    final response = api.gradebooksCreate(createGradebookInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGradebookInput** | [**CreateGradebookInput**](CreateGradebookInput.md)|  |

### Return type

[**GradebookDto**](GradebookDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebooksHistory**
> GradeHistoryDto gradebooksHistory(cellId, id, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getGradebooksApi();
final String cellId = cellId_example; // String |
final num id = 8.14; // num |
final String cursor = cursor_example; // String |

try {
    final response = api.gradebooksHistory(cellId, id, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cellId** | **String**|  |
 **id** | **num**|  |
 **cursor** | **String**|  | [optional]

### Return type

[**GradeHistoryDto**](GradeHistoryDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebooksList**
> GradebookListDto gradebooksList(cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getGradebooksApi();
final num cursor = 8.14; // num |

try {
    final response = api.gradebooksList(cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **num**|  | [optional]

### Return type

[**GradebookListDto**](GradebookListDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebooksLock**
> GradebookDto gradebooksLock(xIdempotencyKey, id, lockInput)



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

final api = ApiClientDart().getGradebooksApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final LockInput lockInput = ; // LockInput |

try {
    final response = api.gradebooksLock(xIdempotencyKey, id, lockInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksLock: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **lockInput** | [**LockInput**](LockInput.md)|  |

### Return type

[**GradebookDto**](GradebookDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebooksSyncRoster**
> GradebookDto gradebooksSyncRoster(xIdempotencyKey, id, lockInput)



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

final api = ApiClientDart().getGradebooksApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final LockInput lockInput = ; // LockInput |

try {
    final response = api.gradebooksSyncRoster(xIdempotencyKey, id, lockInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GradebooksApi->gradebooksSyncRoster: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **lockInput** | [**LockInput**](LockInput.md)|  |

### Return type

[**GradebookDto**](GradebookDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
