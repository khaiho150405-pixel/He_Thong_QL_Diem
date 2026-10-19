//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:api_client_dart/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client_dart/src/model/cancel_batch_input.dart';
import 'package:api_client_dart/src/model/error_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_receipt_dto.dart';

class RecognitionBatchesApi {
  final Dio _dio;

  const RecognitionBatchesApi(this._dio);

  /// recognitionBatchCancel
  ///
  ///
  /// Parameters:
  /// * [xIdempotencyKey]
  /// * [batchId]
  /// * [gradebookId]
  /// * [cancelBatchInput]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RecognitionBatchDto] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RecognitionBatchDto>> recognitionBatchCancel({
    required String xIdempotencyKey,
    required String batchId,
    required num gradebookId,
    required CancelBatchInput cancelBatchInput,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path =
        r'/api/v1/gradebooks/{gradebookId}/recognition-batches/{batchId}/cancel'
            .replaceAll(
              '{'
              r'batchId'
              '}',
              batchId.toString(),
            )
            .replaceAll(
              '{'
              r'gradebookId'
              '}',
              gradebookId.toString(),
            );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'x-idempotency-key': xIdempotencyKey,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'qld_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
          {
            'type': 'apiKey',
            'name': 'csrf',
            'keyName': 'x-csrf-token',
            'where': 'header',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      _bodyData = jsonEncode(cancelBatchInput);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    RecognitionBatchDto? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<RecognitionBatchDto, RecognitionBatchDto>(
              rawData,
              'RecognitionBatchDto',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<RecognitionBatchDto>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// recognitionBatchDetail
  ///
  ///
  /// Parameters:
  /// * [batchId]
  /// * [gradebookId]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RecognitionBatchDto] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RecognitionBatchDto>> recognitionBatchDetail({
    required String batchId,
    required num gradebookId,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path =
        r'/api/v1/gradebooks/{gradebookId}/recognition-batches/{batchId}'
            .replaceAll(
              '{'
              r'batchId'
              '}',
              batchId.toString(),
            )
            .replaceAll(
              '{'
              r'gradebookId'
              '}',
              gradebookId.toString(),
            );
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{...?headers},
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'qld_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    RecognitionBatchDto? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<RecognitionBatchDto, RecognitionBatchDto>(
              rawData,
              'RecognitionBatchDto',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<RecognitionBatchDto>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// recognitionBatchUpload
  ///
  ///
  /// Parameters:
  /// * [xIdempotencyKey]
  /// * [gradebookId]
  /// * [images] - Ảnh các trang theo thứ tự (trang 1 đứng đầu)
  /// * [templateId]
  /// * [components] - JSON `[{\\\"templateColumnIndex\\\": n, \\\"componentId\\\": m}]` (1–20 mục); cột mẫu phải là cột điểm và khớp thành phần theo ánh xạ gợi ý
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RecognitionBatchReceiptDto] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RecognitionBatchReceiptDto>> recognitionBatchUpload({
    required String xIdempotencyKey,
    required num gradebookId,
    required List<MultipartFile> images,
    required int templateId,
    required String components,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/gradebooks/{gradebookId}/recognition-batches'
        .replaceAll(
          '{'
          r'gradebookId'
          '}',
          gradebookId.toString(),
        );
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'x-idempotency-key': xIdempotencyKey,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'apiKey',
            'name': 'cookie',
            'keyName': 'qld_session',
            'where': '',
          },
          {'type': 'http', 'scheme': 'bearer', 'name': 'bearer'},
          {
            'type': 'apiKey',
            'name': 'csrf',
            'keyName': 'x-csrf-token',
            'where': 'header',
          },
        ],
        ...?extra,
      },
      contentType: 'multipart/form-data',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {} catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(_dio.options, _path),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    RecognitionBatchReceiptDto? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<RecognitionBatchReceiptDto, RecognitionBatchReceiptDto>(
              rawData,
              'RecognitionBatchReceiptDto',
              growable: true,
            );
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<RecognitionBatchReceiptDto>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }
}
