# api_client_dart.api.ReviewApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**reviewApprove**](ReviewApi.md#reviewapprove) | **POST** /api/v1/gradebooks/{gradebookId}/recognition-tickets/{ticketId}/approve |


# **reviewApprove**
> ReviewApprovalResultDto reviewApprove(xIdempotencyKey, ticketId, gradebookId, reviewApprovalInput)



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

final api = ApiClientDart().getReviewApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final String ticketId = ticketId_example; // String |
final num gradebookId = 8.14; // num |
final ReviewApprovalInput reviewApprovalInput = ; // ReviewApprovalInput |

try {
    final response = api.reviewApprove(xIdempotencyKey, ticketId, gradebookId, reviewApprovalInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReviewApi->reviewApprove: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **ticketId** | **String**|  |
 **gradebookId** | **num**|  |
 **reviewApprovalInput** | [**ReviewApprovalInput**](ReviewApprovalInput.md)|  |

### Return type

[**ReviewApprovalResultDto**](ReviewApprovalResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
