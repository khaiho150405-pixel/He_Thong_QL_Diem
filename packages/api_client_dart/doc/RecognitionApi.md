# api_client_dart.api.RecognitionApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**recognitionCancel**](RecognitionApi.md#recognitioncancel) | **POST** /api/v1/gradebooks/{gradebookId}/recognition-tickets/{ticketId}/cancel |
[**recognitionDetail**](RecognitionApi.md#recognitiondetail) | **GET** /api/v1/gradebooks/{gradebookId}/recognition-tickets/{ticketId} |
[**recognitionList**](RecognitionApi.md#recognitionlist) | **GET** /api/v1/gradebooks/{gradebookId}/recognition-tickets |
[**recognitionUpload**](RecognitionApi.md#recognitionupload) | **POST** /api/v1/gradebooks/{gradebookId}/recognition-tickets |


# **recognitionCancel**
> RecognitionTicketDetailDto recognitionCancel(xIdempotencyKey, ticketId, gradebookId, cancelTicketInput)



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

final api = ApiClientDart().getRecognitionApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final String ticketId = ticketId_example; // String |
final num gradebookId = 8.14; // num |
final CancelTicketInput cancelTicketInput = ; // CancelTicketInput |

try {
    final response = api.recognitionCancel(xIdempotencyKey, ticketId, gradebookId, cancelTicketInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionApi->recognitionCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **ticketId** | **String**|  |
 **gradebookId** | **num**|  |
 **cancelTicketInput** | [**CancelTicketInput**](CancelTicketInput.md)|  |

### Return type

[**RecognitionTicketDetailDto**](RecognitionTicketDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recognitionDetail**
> RecognitionTicketDetailDto recognitionDetail(ticketId, gradebookId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getRecognitionApi();
final String ticketId = ticketId_example; // String |
final num gradebookId = 8.14; // num |

try {
    final response = api.recognitionDetail(ticketId, gradebookId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionApi->recognitionDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **ticketId** | **String**|  |
 **gradebookId** | **num**|  |

### Return type

[**RecognitionTicketDetailDto**](RecognitionTicketDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recognitionList**
> List<RecognitionTicketDto> recognitionList(gradebookId, includeCancelled)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getRecognitionApi();
final num gradebookId = 8.14; // num |
final bool includeCancelled = true; // bool | true: hiện cả phiếu đã hủy (DA_HUY); mặc định ẩn

try {
    final response = api.recognitionList(gradebookId, includeCancelled);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionApi->recognitionList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gradebookId** | **num**|  |
 **includeCancelled** | **bool**| true: hiện cả phiếu đã hủy (DA_HUY); mặc định ẩn | [optional]

### Return type

[**List&lt;RecognitionTicketDto&gt;**](RecognitionTicketDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recognitionUpload**
> RecognitionReceiptDto recognitionUpload(xIdempotencyKey, gradebookId, image, componentId, declaredRows)



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

final api = ApiClientDart().getRecognitionApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num gradebookId = 8.14; // num |
final MultipartFile image = BINARY_DATA_HERE; // MultipartFile |
final int componentId = 56; // int |
final int declaredRows = 56; // int | Deprecated và bị bỏ qua: hệ thống tự chốt danh sách lớp khi tạo phiếu (ADR-0015).

try {
    final response = api.recognitionUpload(xIdempotencyKey, gradebookId, image, componentId, declaredRows);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionApi->recognitionUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **gradebookId** | **num**|  |
 **image** | **MultipartFile**|  |
 **componentId** | **int**|  |
 **declaredRows** | **int**| Deprecated và bị bỏ qua: hệ thống tự chốt danh sách lớp khi tạo phiếu (ADR-0015). | [optional]

### Return type

[**RecognitionReceiptDto**](RecognitionReceiptDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
