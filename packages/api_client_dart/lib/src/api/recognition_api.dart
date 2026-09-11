//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

// ignore: unused_import
import 'dart:convert';
import 'package:api_client_dart/src/deserialize.dart';
import 'package:dio/dio.dart';

import 'package:api_client_dart/src/model/error_dto.dart';
import 'package:api_client_dart/src/model/recognition_receipt_dto.dart';

class RecognitionApi {
  final Dio _dio;

  const RecognitionApi(this._dio);

  /// recognitionUpload
  ///
  ///
  /// Parameters:
  /// * [xIdempotencyKey]
  /// * [gradebookId]
  /// * [image]
  /// * [componentId]
  /// * [declaredRows]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [RecognitionReceiptDto] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<RecognitionReceiptDto>> recognitionUpload({
    required String xIdempotencyKey,
    required num gradebookId,
    required MultipartFile image,
    required int componentId,
    required int declaredRows,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/api/v1/gradebooks/{gradebookId}/recognition-tickets'
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

    RecognitionReceiptDto? _responseData;

    try {
      final rawData = _response.data;
      _responseData = rawData == null
          ? null
          : deserialize<RecognitionReceiptDto, RecognitionReceiptDto>(
              rawData,
              'RecognitionReceiptDto',
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

    return Response<RecognitionReceiptDto>(
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
