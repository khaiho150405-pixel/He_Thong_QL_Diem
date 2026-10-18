# api_client_dart.api.FormTemplatesApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**formTemplatesActivate**](FormTemplatesApi.md#formtemplatesactivate) | **POST** /api/v1/catalog/form-templates/{id}/activate |
[**formTemplatesAnalyze**](FormTemplatesApi.md#formtemplatesanalyze) | **POST** /api/v1/catalog/form-templates/analyze |
[**formTemplatesCreate**](FormTemplatesApi.md#formtemplatescreate) | **POST** /api/v1/catalog/form-templates |
[**formTemplatesCreateVersion**](FormTemplatesApi.md#formtemplatescreateversion) | **POST** /api/v1/catalog/form-templates/{id}/versions |
[**formTemplatesDetail**](FormTemplatesApi.md#formtemplatesdetail) | **GET** /api/v1/catalog/form-templates/{id} |
[**formTemplatesList**](FormTemplatesApi.md#formtemplateslist) | **GET** /api/v1/catalog/form-templates |
[**formTemplatesRetire**](FormTemplatesApi.md#formtemplatesretire) | **POST** /api/v1/catalog/form-templates/{id}/retire |
[**formTemplatesTryTemplate**](FormTemplatesApi.md#formtemplatestrytemplate) | **POST** /api/v1/catalog/form-templates/{id}/try |
[**formTemplatesUpdate**](FormTemplatesApi.md#formtemplatesupdate) | **PUT** /api/v1/catalog/form-templates/{id} |


# **formTemplatesActivate**
> TemplateDetailDto formTemplatesActivate(id, expectedVersionInput)



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

final api = ApiClientDart().getFormTemplatesApi();
final num id = 8.14; // num |
final ExpectedVersionInput expectedVersionInput = ; // ExpectedVersionInput |

try {
    final response = api.formTemplatesActivate(id, expectedVersionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesActivate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **expectedVersionInput** | [**ExpectedVersionInput**](ExpectedVersionInput.md)|  |

### Return type

[**TemplateDetailDto**](TemplateDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesAnalyze**
> AnalyzeResultDto formTemplatesAnalyze(image)



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

final api = ApiClientDart().getFormTemplatesApi();
final MultipartFile image = BINARY_DATA_HERE; // MultipartFile |

try {
    final response = api.formTemplatesAnalyze(image);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesAnalyze: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **image** | **MultipartFile**|  |

### Return type

[**AnalyzeResultDto**](AnalyzeResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesCreate**
> TemplateDetailDto formTemplatesCreate(image, definition)



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

final api = ApiClientDart().getFormTemplatesApi();
final MultipartFile image = BINARY_DATA_HERE; // MultipartFile |
final String definition = definition_example; // String | JSON của TemplateDefinitionInput (name, description, columns)

try {
    final response = api.formTemplatesCreate(image, definition);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesCreate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **image** | **MultipartFile**|  |
 **definition** | **String**| JSON của TemplateDefinitionInput (name, description, columns) |

### Return type

[**TemplateDetailDto**](TemplateDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesCreateVersion**
> TemplateDetailDto formTemplatesCreateVersion(id, versionedDefinitionInput)



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

final api = ApiClientDart().getFormTemplatesApi();
final num id = 8.14; // num |
final VersionedDefinitionInput versionedDefinitionInput = ; // VersionedDefinitionInput |

try {
    final response = api.formTemplatesCreateVersion(id, versionedDefinitionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesCreateVersion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **versionedDefinitionInput** | [**VersionedDefinitionInput**](VersionedDefinitionInput.md)|  |

### Return type

[**TemplateDetailDto**](TemplateDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesDetail**
> TemplateDetailDto formTemplatesDetail(id)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getFormTemplatesApi();
final num id = 8.14; // num |

try {
    final response = api.formTemplatesDetail(id);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesDetail: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |

### Return type

[**TemplateDetailDto**](TemplateDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesList**
> TemplatePageDto formTemplatesList(status, cursor)



### Example
```dart
import 'package:api_client_dart/api.dart';
// TODO Configure API key authorization: cookie
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('cookie').apiKeyPrefix = 'Bearer';

final api = ApiClientDart().getFormTemplatesApi();
final String status = status_example; // String |
final String cursor = cursor_example; // String |

try {
    final response = api.formTemplatesList(status, cursor);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesList: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **status** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]

### Return type

[**TemplatePageDto**](TemplatePageDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesRetire**
> TemplateDetailDto formTemplatesRetire(id, expectedVersionInput)



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

final api = ApiClientDart().getFormTemplatesApi();
final num id = 8.14; // num |
final ExpectedVersionInput expectedVersionInput = ; // ExpectedVersionInput |

try {
    final response = api.formTemplatesRetire(id, expectedVersionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesRetire: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **expectedVersionInput** | [**ExpectedVersionInput**](ExpectedVersionInput.md)|  |

### Return type

[**TemplateDetailDto**](TemplateDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesTryTemplate**
> TryResultDto formTemplatesTryTemplate(id, image)



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

final api = ApiClientDart().getFormTemplatesApi();
final num id = 8.14; // num |
final MultipartFile image = BINARY_DATA_HERE; // MultipartFile |

try {
    final response = api.formTemplatesTryTemplate(id, image);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesTryTemplate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **image** | **MultipartFile**|  |

### Return type

[**TryResultDto**](TryResultDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **formTemplatesUpdate**
> TemplateDetailDto formTemplatesUpdate(id, versionedDefinitionInput)



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

final api = ApiClientDart().getFormTemplatesApi();
final num id = 8.14; // num |
final VersionedDefinitionInput versionedDefinitionInput = ; // VersionedDefinitionInput |

try {
    final response = api.formTemplatesUpdate(id, versionedDefinitionInput);
    print(response);
} catch on DioException (e) {
    print('Exception when calling FormTemplatesApi->formTemplatesUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **num**|  |
 **versionedDefinitionInput** | [**VersionedDefinitionInput**](VersionedDefinitionInput.md)|  |

### Return type

[**TemplateDetailDto**](TemplateDetailDto.md)

### Authorization

[cookie](../README.md#cookie), [bearer](../README.md#bearer), [csrf](../README.md#csrf)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
