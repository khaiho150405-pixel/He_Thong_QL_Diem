# api_client_dart.api.RecognitionBatchesApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**recognitionBatchCancel**](RecognitionBatchesApi.md#recognitionbatchcancel) | **POST** /api/v1/gradebooks/{gradebookId}/recognition-batches/{batchId}/cancel |
[**recognitionBatchDetail**](RecognitionBatchesApi.md#recognitionbatchdetail) | **GET** /api/v1/gradebooks/{gradebookId}/recognition-batches/{batchId} |
[**recognitionBatchUpload**](RecognitionBatchesApi.md#recognitionbatchupload) | **POST** /api/v1/gradebooks/{gradebookId}/recognition-batches |


# **recognitionBatchCancel**
> RecognitionBatchDto recognitionBatchCancel(xIdempotencyKey, batchId, gradebookId, cancelBatchInput)



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

final api = ApiClientDart().getRecognitionBatchesApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final String batchId = batchId_example; // String |
final num gradebookId = 8.14; // num |
final CancelBatchInput cancelBatchInput = ; // CancelBatchInput |

try {
    final response = api.recognitionBatchCancel(xIdempotencyKey, batchId, gradebookId, cancelBatchInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionBatchesApi->recognitionBatchCancel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **batchId** | **String**|  |
 **gradebookId** | **num**|  |
 **cancelBatchInput** | [**CancelBatchInput**](CancelBatchInput.md)|  |

### Return type

[**RecognitionBatchDto**](RecognitionBatchDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recognitionBatchDetail**
> RecognitionBatchDto recognitionBatchDetail(batchId, gradebookId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getRecognitionBatchesApi();
final String batchId = batchId_example; // String |
final num gradebookId = 8.14; // num |

try {
    final response = api.recognitionBatchDetail(batchId, gradebookId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionBatchesApi->recognitionBatchDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **batchId** | **String**|  |
 **gradebookId** | **num**|  |

### Return type

[**RecognitionBatchDto**](RecognitionBatchDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recognitionBatchUpload**
> RecognitionBatchReceiptDto recognitionBatchUpload(xIdempotencyKey, gradebookId, images, templateId, components)



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

final api = ApiClientDart().getRecognitionBatchesApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final num gradebookId = 8.14; // num |
final List<MultipartFile> images = /path/to/file.txt; // List<MultipartFile> | Ảnh các trang theo thứ tự (trang 1 đứng đầu)
final int templateId = 56; // int |
final String components = components_example; // String | JSON `[{\\\"templateColumnIndex\\\": n, \\\"componentId\\\": m}]` (1–20 mục); cột mẫu phải là cột điểm và khớp thành phần theo ánh xạ gợi ý

try {
    final response = api.recognitionBatchUpload(xIdempotencyKey, gradebookId, images, templateId, components);
    print(response);
} catch on DioException (e) {
    print('Exception when calling RecognitionBatchesApi->recognitionBatchUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **gradebookId** | **num**|  |
 **images** | [**List&lt;MultipartFile&gt;**](MultipartFile.md)| Ảnh các trang theo thứ tự (trang 1 đứng đầu) |
 **templateId** | **int**|  |
 **components** | **String**| JSON `[{\\\"templateColumnIndex\\\": n, \\\"componentId\\\": m}]` (1–20 mục); cột mẫu phải là cột điểm và khớp thành phần theo ánh xạ gợi ý |

### Return type

[**RecognitionBatchReceiptDto**](RecognitionBatchReceiptDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
