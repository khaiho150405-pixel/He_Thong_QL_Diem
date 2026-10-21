# api_client_dart.api.SemestersApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**semesterDeadlinesInitialize**](SemestersApi.md#semesterdeadlinesinitialize) | **POST** /api/v1/catalog/semesters/{id}/gradebooks/initialize |
[**semesterDeadlinesList**](SemestersApi.md#semesterdeadlineslist) | **GET** /api/v1/catalog/semesters/{id}/deadlines |
[**semesterDeadlinesPublishReadiness**](SemestersApi.md#semesterdeadlinespublishreadiness) | **GET** /api/v1/catalog/semesters/{id}/publish-readiness |
[**semesterDeadlinesSet**](SemestersApi.md#semesterdeadlinesset) | **PUT** /api/v1/catalog/semesters/{id}/deadlines/{type} |
[**semestersCreate**](SemestersApi.md#semesterscreate) | **POST** /api/v1/catalog/semesters |
[**semestersList**](SemestersApi.md#semesterslist) | **GET** /api/v1/catalog/semesters |
[**semestersRemove**](SemestersApi.md#semestersremove) | **DELETE** /api/v1/catalog/semesters/{id} |
[**semestersUpdate**](SemestersApi.md#semestersupdate) | **PUT** /api/v1/catalog/semesters/{id} |


# **semesterDeadlinesInitialize**
> InitializeGradebooksResultDto semesterDeadlinesInitialize(xIdempotencyKey, id)



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

final api = ApiClientDart().getSemestersApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |

try {
    final response = api.semesterDeadlinesInitialize(xIdempotencyKey, id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semesterDeadlinesInitialize: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |

### Return type

[**InitializeGradebooksResultDto**](InitializeGradebooksResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semesterDeadlinesList**
> SemesterDeadlinesDto semesterDeadlinesList(id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getSemestersApi();
final num id = 8.14; // num |

try {
    final response = api.semesterDeadlinesList(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semesterDeadlinesList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

[**SemesterDeadlinesDto**](SemesterDeadlinesDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semesterDeadlinesPublishReadiness**
> PublishReadinessDto semesterDeadlinesPublishReadiness(id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getSemestersApi();
final num id = 8.14; // num |

try {
    final response = api.semesterDeadlinesPublishReadiness(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semesterDeadlinesPublishReadiness: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

[**PublishReadinessDto**](PublishReadinessDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semesterDeadlinesSet**
> SemesterDeadlineDto semesterDeadlinesSet(type, id, semesterDeadlineInput)



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

final api = ApiClientDart().getSemestersApi();
final String type = type_example; // String |
final num id = 8.14; // num |
final SemesterDeadlineInput semesterDeadlineInput = ; // SemesterDeadlineInput |

try {
    final response = api.semesterDeadlinesSet(type, id, semesterDeadlineInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semesterDeadlinesSet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **type** | **String**|  |
 **id** | **num**|  |
 **semesterDeadlineInput** | [**SemesterDeadlineInput**](SemesterDeadlineInput.md)|  |

### Return type

[**SemesterDeadlineDto**](SemesterDeadlineDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semestersCreate**
> SemestersDto semestersCreate(semestersInput)



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

final api = ApiClientDart().getSemestersApi();
final SemestersInput semestersInput = ; // SemestersInput |

try {
    final response = api.semestersCreate(semestersInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semestersCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **semestersInput** | [**SemestersInput**](SemestersInput.md)|  |

### Return type

[**SemestersDto**](SemestersDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semestersList**
> SemestersPage semestersList(yearId, q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getSemestersApi();
final num yearId = 8.14; // num | Chỉ học kỳ thuộc năm học này; vắng = tất cả
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.semestersList(yearId, q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semestersList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **yearId** | **num**| Chỉ học kỳ thuộc năm học này; vắng = tất cả | [optional]
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**SemestersPage**](SemestersPage.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **semestersRemove**
> semestersRemove(id)



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

final api = ApiClientDart().getSemestersApi();
final num id = 8.14; // num |

try {
    api.semestersRemove(id);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semestersRemove: $e\n');
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

# **semestersUpdate**
> SemestersDto semestersUpdate(id, semestersInput)



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

final api = ApiClientDart().getSemestersApi();
final num id = 8.14; // num |
final SemestersInput semestersInput = ; // SemestersInput |

try {
    final response = api.semestersUpdate(id, semestersInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SemestersApi->semestersUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **semestersInput** | [**SemestersInput**](SemestersInput.md)|  |

### Return type

[**SemestersDto**](SemestersDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
