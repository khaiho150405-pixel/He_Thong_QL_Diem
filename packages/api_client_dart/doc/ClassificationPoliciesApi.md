# api_client_dart.api.ClassificationPoliciesApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**classificationPoliciesActivate**](ClassificationPoliciesApi.md#classificationpoliciesactivate) | **POST** /api/v1/classification-policies/activate |
[**classificationPoliciesActive**](ClassificationPoliciesApi.md#classificationpoliciesactive) | **GET** /api/v1/classification-policies/active |


# **classificationPoliciesActivate**
> ClassificationPolicyDto classificationPoliciesActivate(xIdempotencyKey, activateClassificationPolicyInput)



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

final api = ApiClientDart().getClassificationPoliciesApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final ActivateClassificationPolicyInput activateClassificationPolicyInput = ; // ActivateClassificationPolicyInput |

try {
    final response = api.classificationPoliciesActivate(xIdempotencyKey, activateClassificationPolicyInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ClassificationPoliciesApi->classificationPoliciesActivate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **activateClassificationPolicyInput** | [**ActivateClassificationPolicyInput**](ActivateClassificationPolicyInput.md)|  |

### Return type

[**ClassificationPolicyDto**](ClassificationPolicyDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **classificationPoliciesActive**
> ClassificationPolicyDto classificationPoliciesActive()



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getClassificationPoliciesApi();

try {
    final response = api.classificationPoliciesActive();
    print(response);
} catch on DioException (e) {
    print('Exception when calling ClassificationPoliciesApi->classificationPoliciesActive: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ClassificationPolicyDto**](ClassificationPolicyDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
