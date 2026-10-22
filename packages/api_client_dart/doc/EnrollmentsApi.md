# api_client_dart.api.EnrollmentsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**classPromotionPreview**](EnrollmentsApi.md#classpromotionpreview) | **GET** /api/v1/classes/{id}/promotion-preview |
[**classPromotionPromote**](EnrollmentsApi.md#classpromotionpromote) | **POST** /api/v1/classes/{id}/promotion |
[**studentEnrollmentsList**](EnrollmentsApi.md#studentenrollmentslist) | **GET** /api/v1/students/{id}/enrollments |
[**studentEnrollmentsReenroll**](EnrollmentsApi.md#studentenrollmentsreenroll) | **POST** /api/v1/students/{id}/reenroll |
[**studentEnrollmentsTransfer**](EnrollmentsApi.md#studentenrollmentstransfer) | **POST** /api/v1/students/{id}/transfer |
[**studentEnrollmentsWithdraw**](EnrollmentsApi.md#studentenrollmentswithdraw) | **POST** /api/v1/students/{id}/withdraw |


# **classPromotionPreview**
> PromotionPreviewDto classPromotionPreview(targetYearId, id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getEnrollmentsApi();
final num targetYearId = 8.14; // num |
final num id = 8.14; // num |

try {
    final response = api.classPromotionPreview(targetYearId, id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EnrollmentsApi->classPromotionPreview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **targetYearId** | **num**|  |
 **id** | **num**|  |

### Return type

[**PromotionPreviewDto**](PromotionPreviewDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **classPromotionPromote**
> PromotionResultDto classPromotionPromote(xIdempotencyKey, id, promotionInput)



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

final api = ApiClientDart().getEnrollmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final PromotionInput promotionInput = ; // PromotionInput |

try {
    final response = api.classPromotionPromote(xIdempotencyKey, id, promotionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EnrollmentsApi->classPromotionPromote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **promotionInput** | [**PromotionInput**](PromotionInput.md)|  |

### Return type

[**PromotionResultDto**](PromotionResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **studentEnrollmentsList**
> EnrollmentListDto studentEnrollmentsList(id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getEnrollmentsApi();
final num id = 8.14; // num |

try {
    final response = api.studentEnrollmentsList(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EnrollmentsApi->studentEnrollmentsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

[**EnrollmentListDto**](EnrollmentListDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **studentEnrollmentsReenroll**
> EnrollmentResultDto studentEnrollmentsReenroll(xIdempotencyKey, id, reenrollInput)



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

final api = ApiClientDart().getEnrollmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final ReenrollInput reenrollInput = ; // ReenrollInput |

try {
    final response = api.studentEnrollmentsReenroll(xIdempotencyKey, id, reenrollInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EnrollmentsApi->studentEnrollmentsReenroll: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **reenrollInput** | [**ReenrollInput**](ReenrollInput.md)|  |

### Return type

[**EnrollmentResultDto**](EnrollmentResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **studentEnrollmentsTransfer**
> TransferResultDto studentEnrollmentsTransfer(xIdempotencyKey, id, transferInput)



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

final api = ApiClientDart().getEnrollmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final TransferInput transferInput = ; // TransferInput |

try {
    final response = api.studentEnrollmentsTransfer(xIdempotencyKey, id, transferInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EnrollmentsApi->studentEnrollmentsTransfer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **transferInput** | [**TransferInput**](TransferInput.md)|  |

### Return type

[**TransferResultDto**](TransferResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **studentEnrollmentsWithdraw**
> EnrollmentResultDto studentEnrollmentsWithdraw(xIdempotencyKey, id, withdrawInput)



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

final api = ApiClientDart().getEnrollmentsApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num id = 8.14; // num |
final WithdrawInput withdrawInput = ; // WithdrawInput |

try {
    final response = api.studentEnrollmentsWithdraw(xIdempotencyKey, id, withdrawInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling EnrollmentsApi->studentEnrollmentsWithdraw: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **id** | **num**|  |
 **withdrawInput** | [**WithdrawInput**](WithdrawInput.md)|  |

### Return type

[**EnrollmentResultDto**](EnrollmentResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
