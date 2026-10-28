# api_client_dart.api.SchoolApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**schoolProfileAdminRemoveLogo**](SchoolApi.md#schoolprofileadminremovelogo) | **DELETE** /api/v1/admin/school-profile/logo |
[**schoolProfileAdminSetLogo**](SchoolApi.md#schoolprofileadminsetlogo) | **PUT** /api/v1/admin/school-profile/logo |
[**schoolProfileAdminUpdate**](SchoolApi.md#schoolprofileadminupdate) | **PUT** /api/v1/admin/school-profile |
[**schoolProfilePublicLogo**](SchoolApi.md#schoolprofilepubliclogo) | **GET** /api/v1/school-profile/logo |
[**schoolProfilePublicProfile**](SchoolApi.md#schoolprofilepublicprofile) | **GET** /api/v1/school-profile |


# **schoolProfileAdminRemoveLogo**
> SchoolProfileDto schoolProfileAdminRemoveLogo(expectedVersion, xIdempotencyKey)



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

final api = ApiClientDart().getSchoolApi();
final num expectedVersion = 8.14; // num |
final String xIdempotencyKey = xIdempotencyKey_example; // String |

try {
    final response = api.schoolProfileAdminRemoveLogo(expectedVersion, xIdempotencyKey);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolApi->schoolProfileAdminRemoveLogo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **expectedVersion** | **num**|  |
 **xIdempotencyKey** | **String**|  |

### Return type

[**SchoolProfileDto**](SchoolProfileDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **schoolProfileAdminSetLogo**
> SchoolProfileDto schoolProfileAdminSetLogo(xIdempotencyKey, file, expectedVersion)



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

final api = ApiClientDart().getSchoolApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final MultipartFile file = BINARY_DATA_HERE; // MultipartFile |
final int expectedVersion = 56; // int |

try {
    final response = api.schoolProfileAdminSetLogo(xIdempotencyKey, file, expectedVersion);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolApi->schoolProfileAdminSetLogo: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **file** | **MultipartFile**|  |
 **expectedVersion** | **int**|  |

### Return type

[**SchoolProfileDto**](SchoolProfileDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **schoolProfileAdminUpdate**
> SchoolProfileDto schoolProfileAdminUpdate(xIdempotencyKey, updateSchoolProfileInput)



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

final api = ApiClientDart().getSchoolApi();
final String xIdempotencyKey = xIdempotencyKey_example; // String |
final UpdateSchoolProfileInput updateSchoolProfileInput = ; // UpdateSchoolProfileInput |

try {
    final response = api.schoolProfileAdminUpdate(xIdempotencyKey, updateSchoolProfileInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolApi->schoolProfileAdminUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xIdempotencyKey** | **String**|  |
 **updateSchoolProfileInput** | [**UpdateSchoolProfileInput**](UpdateSchoolProfileInput.md)|  |

### Return type

[**SchoolProfileDto**](SchoolProfileDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **schoolProfilePublicLogo**
> Uint8List schoolProfilePublicLogo()



### Example
```dart
import 'package:api_client_dart/api.dart';

final api = ApiClientDart().getSchoolApi();

try {
    final response = api.schoolProfilePublicLogo();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolApi->schoolProfilePublicLogo: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Uint8List**](Uint8List.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: image/png, image/jpeg, application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **schoolProfilePublicProfile**
> SchoolProfileDto schoolProfilePublicProfile()



### Example
```dart
import 'package:api_client_dart/api.dart';

final api = ApiClientDart().getSchoolApi();

try {
    final response = api.schoolProfilePublicProfile();
    print(response);
} catch on DioException (e) {
    print('Exception when calling SchoolApi->schoolProfilePublicProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SchoolProfileDto**](SchoolProfileDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
