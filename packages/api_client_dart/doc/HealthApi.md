# api_client_dart.api.HealthApi

## Load the API package
```dart
import 'package:api_client_dart/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthLive**](HealthApi.md#healthlive) | **GET** /api/v1/health/live |
[**healthReady**](HealthApi.md#healthready) | **GET** /api/v1/health/ready |


# **healthLive**
> HealthDto healthLive()



### Example
```dart
import 'package:api_client_dart/api.dart';

final api = ApiClientDart().getHealthApi();

try {
    final response = api.healthLive();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->healthLive: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthDto**](HealthDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthReady**
> HealthDto healthReady()



### Example
```dart
import 'package:api_client_dart/api.dart';

final api = ApiClientDart().getHealthApi();

try {
    final response = api.healthReady();
    print(response);
} catch on DioException (e) {
    print('Exception when calling HealthApi->healthReady: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthDto**](HealthDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
