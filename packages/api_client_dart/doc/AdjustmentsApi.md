# api_client_dart.api.AdjustmentsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**adjustmentsApprove**](AdjustmentsApi.md#adjustmentsapprove) | **POST** /api/v1/adjustments/{adjId}/approve |
[**adjustmentsCancel**](AdjustmentsApi.md#adjustmentscancel) | **POST** /api/v1/adjustments/{adjId}/cancel |
[**adjustmentsDetail**](AdjustmentsApi.md#adjustmentsdetail) | **GET** /api/v1/adjustments/{adjId} |
[**adjustmentsList**](AdjustmentsApi.md#adjustmentslist) | **GET** /api/v1/adjustments |
[**adjustmentsReject**](AdjustmentsApi.md#adjustmentsreject) | **POST** /api/v1/adjustments/{adjId}/reject |
[**gradebookAdjustmentsListForBook**](AdjustmentsApi.md#gradebookadjustmentslistforbook) | **GET** /api/v1/gradebooks/{id}/adjustments |
[**gradebookAdjustmentsSubmit**](AdjustmentsApi.md#gradebookadjustmentssubmit) | **POST** /api/v1/gradebooks/{id}/adjustments |


# **adjustmentsApprove**
> AdjustmentDto adjustmentsApprove(xIdempotencyKey, adjId, adjustmentVersionInput)



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

final api = ApiClientDart().getAdjustmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final String adjId = adjId_example; // String |
final AdjustmentVersionInput adjustmentVersionInput = ; // AdjustmentVersionInput |

try {
    final response = api.adjustmentsApprove(xIdempotencyKey, adjId, adjustmentVersionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->adjustmentsApprove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **adjId** | **String**|  |
 **adjustmentVersionInput** | [**AdjustmentVersionInput**](AdjustmentVersionInput.md)|  |

### Return type

[**AdjustmentDto**](AdjustmentDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adjustmentsCancel**
> AdjustmentDto adjustmentsCancel(xIdempotencyKey, adjId, adjustmentVersionInput)



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

final api = ApiClientDart().getAdjustmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final String adjId = adjId_example; // String |
final AdjustmentVersionInput adjustmentVersionInput = ; // AdjustmentVersionInput |

try {
    final response = api.adjustmentsCancel(xIdempotencyKey, adjId, adjustmentVersionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->adjustmentsCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **adjId** | **String**|  |
 **adjustmentVersionInput** | [**AdjustmentVersionInput**](AdjustmentVersionInput.md)|  |

### Return type

[**AdjustmentDto**](AdjustmentDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adjustmentsDetail**
> AdjustmentDto adjustmentsDetail(adjId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAdjustmentsApi();
final String adjId = adjId_example; // String |

try {
    final response = api.adjustmentsDetail(adjId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->adjustmentsDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adjId** | **String**|  |

### Return type

[**AdjustmentDto**](AdjustmentDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adjustmentsList**
> AdjustmentPageDto adjustmentsList(cursor, status)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAdjustmentsApi();
final String cursor = cursor_example; // String |
final String status = status_example; // String |

try {
    final response = api.adjustmentsList(cursor, status);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->adjustmentsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**|  | [optional]
 **status** | **String**|  | [optional]

### Return type

[**AdjustmentPageDto**](AdjustmentPageDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **adjustmentsReject**
> AdjustmentDto adjustmentsReject(xIdempotencyKey, adjId, adjustmentRejectInput)



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

final api = ApiClientDart().getAdjustmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final String adjId = adjId_example; // String |
final AdjustmentRejectInput adjustmentRejectInput = ; // AdjustmentRejectInput |

try {
    final response = api.adjustmentsReject(xIdempotencyKey, adjId, adjustmentRejectInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->adjustmentsReject: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **adjId** | **String**|  |
 **adjustmentRejectInput** | [**AdjustmentRejectInput**](AdjustmentRejectInput.md)|  |

### Return type

[**AdjustmentDto**](AdjustmentDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebookAdjustmentsListForBook**
> AdjustmentListDto gradebookAdjustmentsListForBook(id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getAdjustmentsApi();
final num id = 8.14; // num |

try {
    final response = api.gradebookAdjustmentsListForBook(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->gradebookAdjustmentsListForBook: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

[**AdjustmentListDto**](AdjustmentListDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **gradebookAdjustmentsSubmit**
> AdjustmentDto gradebookAdjustmentsSubmit(xIdempotencyKey, id, adjustmentInput)



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

final api = ApiClientDart().getAdjustmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final AdjustmentInput adjustmentInput = ; // AdjustmentInput |

try {
    final response = api.gradebookAdjustmentsSubmit(xIdempotencyKey, id, adjustmentInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling AdjustmentsApi->gradebookAdjustmentsSubmit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **adjustmentInput** | [**AdjustmentInput**](AdjustmentInput.md)|  |

### Return type

[**AdjustmentDto**](AdjustmentDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
