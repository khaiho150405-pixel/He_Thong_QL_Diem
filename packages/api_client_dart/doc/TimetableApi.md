# api_client_dart.api.TimetableApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**timetableCreate**](TimetableApi.md#timetablecreate) | **POST** /api/v1/timetable |
[**timetableList**](TimetableApi.md#timetablelist) | **GET** /api/v1/timetable |
[**timetableRemove**](TimetableApi.md#timetableremove) | **DELETE** /api/v1/timetable/{id} |
[**timetableUpdate**](TimetableApi.md#timetableupdate) | **PUT** /api/v1/timetable/{id} |


# **timetableCreate**
> TimetableItemDto timetableCreate(createTimetableItemInput)



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

final api = ApiClientDart().getTimetableApi();
final CreateTimetableItemInput createTimetableItemInput = ; // CreateTimetableItemInput |

try {
    final response = api.timetableCreate(createTimetableItemInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimetableApi->timetableCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createTimetableItemInput** | [**CreateTimetableItemInput**](CreateTimetableItemInput.md)|  |

### Return type

[**TimetableItemDto**](TimetableItemDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **timetableList**
> TimetableListDto timetableList(dayOfWeek, semesterId, teacherId, classId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getTimetableApi();
final num dayOfWeek = 8.14; // num |
final num semesterId = 8.14; // num |
final num teacherId = 8.14; // num |
final num classId = 8.14; // num |

try {
    final response = api.timetableList(dayOfWeek, semesterId, teacherId, classId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimetableApi->timetableList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **dayOfWeek** | **num**|  | [optional]
 **semesterId** | **num**|  | [optional]
 **teacherId** | **num**|  | [optional]
 **classId** | **num**|  | [optional]

### Return type

[**TimetableListDto**](TimetableListDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **timetableRemove**
> timetableRemove(id)



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

final api = ApiClientDart().getTimetableApi();
final num id = 8.14; // num |

try {
    api.timetableRemove(id);
} catch on DioException (e) {
    print('Exception when calling TimetableApi->timetableRemove: $e\n');
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

# **timetableUpdate**
> TimetableItemDto timetableUpdate(id, createTimetableItemInput)



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

final api = ApiClientDart().getTimetableApi();
final num id = 8.14; // num |
final CreateTimetableItemInput createTimetableItemInput = ; // CreateTimetableItemInput |

try {
    final response = api.timetableUpdate(id, createTimetableItemInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling TimetableApi->timetableUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **createTimetableItemInput** | [**CreateTimetableItemInput**](CreateTimetableItemInput.md)|  |

### Return type

[**TimetableItemDto**](TimetableItemDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
