# api_client_dart.api.IdentityApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**identityAccounts**](IdentityApi.md#identityaccounts) | **GET** /api/v1/identity/accounts |
[**identityCreateAccount**](IdentityApi.md#identitycreateaccount) | **POST** /api/v1/identity/accounts |
[**identityLogin**](IdentityApi.md#identitylogin) | **POST** /api/v1/identity/login |
[**identityLogout**](IdentityApi.md#identitylogout) | **POST** /api/v1/identity/logout |
[**identityMe**](IdentityApi.md#identityme) | **GET** /api/v1/identity/me |
[**identityPassword**](IdentityApi.md#identitypassword) | **POST** /api/v1/identity/password |
[**identityProfile**](IdentityApi.md#identityprofile) | **GET** /api/v1/identity/profile |
[**identityUpdateAccount**](IdentityApi.md#identityupdateaccount) | **PUT** /api/v1/identity/accounts/{id} |
[**identityUpdateProfile**](IdentityApi.md#identityupdateprofile) | **PUT** /api/v1/identity/profile |


# **identityAccounts**
> AccountsDto identityAccounts(q, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();
final String q = q_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.identityAccounts(q, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityAccounts: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**AccountsDto**](AccountsDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityCreateAccount**
> AccountDto identityCreateAccount(accountInput)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();
final AccountInput accountInput = ; // AccountInput |

try {
    final response = api.identityCreateAccount(accountInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityCreateAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **accountInput** | [**AccountInput**](AccountInput.md)|  |

### Return type

[**AccountDto**](AccountDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityLogin**
> SessionDto identityLogin(loginInput)



### Example
```dart
import 'package:api_client_dart/api.dart';

final api = ApiClientDart().getIdentityApi();
final LoginInput loginInput = ; // LoginInput |

try {
    final response = api.identityLogin(loginInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityLogin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **loginInput** | [**LoginInput**](LoginInput.md)|  |

### Return type

[**SessionDto**](SessionDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityLogout**
> identityLogout()



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();

try {
    api.identityLogout();
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityLogout: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityMe**
> SessionDto identityMe()



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();

try {
    final response = api.identityMe();
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityMe: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SessionDto**](SessionDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityPassword**
> identityPassword(passwordInput)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();
final PasswordInput passwordInput = ; // PasswordInput |

try {
    api.identityPassword(passwordInput);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityPassword: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **passwordInput** | [**PasswordInput**](PasswordInput.md)|  |

### Return type

void (empty response body)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityProfile**
> ProfileDto identityProfile()



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();

try {
    final response = api.identityProfile();
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityProfile: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ProfileDto**](ProfileDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityUpdateAccount**
> AccountDto identityUpdateAccount(id, accountUpdate)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();
final num id = 8.14; // num |
final AccountUpdate accountUpdate = ; // AccountUpdate |

try {
    final response = api.identityUpdateAccount(id, accountUpdate);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityUpdateAccount: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **accountUpdate** | [**AccountUpdate**](AccountUpdate.md)|  |

### Return type

[**AccountDto**](AccountDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **identityUpdateProfile**
> ProfileDto identityUpdateProfile(profileDto)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getIdentityApi();
final ProfileDto profileDto = ; // ProfileDto |

try {
    final response = api.identityUpdateProfile(profileDto);
    print(response);
} catch on DioException (e) {
    print('Exception when calling IdentityApi->identityUpdateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **profileDto** | [**ProfileDto**](ProfileDto.md)|  |

### Return type

[**ProfileDto**](ProfileDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
