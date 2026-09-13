# api_client_dart.api.StudentResultsApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**studentResultsList**](StudentResultsApi.md#studentresultslist) | **GET** /api/v1/students/me/results |


# **studentResultsList**
> StudentResultsDto studentResultsList(termId)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getStudentResultsApi();
final num termId = 8.14; // num |

try {
    final response = api.studentResultsList(termId);
    print(response);
} catch on DioException (e) {
    print('Exception when calling StudentResultsApi->studentResultsList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **termId** | **num**|  | [optional]

### Return type

[**StudentResultsDto**](StudentResultsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
