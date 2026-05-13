import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_method.dart';
import 'api_request.dart';
import 'api_response.dart';

typedef JsonMap = Map<String, dynamic>;
typedef ResponseDecoder<T> = T Function(Object? json);
typedef AuthTokenProvider = FutureOr<String?> Function();
typedef AuthRefreshHandler = Future<bool> Function();

class ApiClient {
  ApiClient({
    required ApiConfig config,
    http.Client? httpClient,
    AuthTokenProvider? tokenProvider,
    AuthRefreshHandler? authRefreshHandler,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider,
        _authRefreshHandler = authRefreshHandler;

  final ApiConfig _config;
  final http.Client _httpClient;
  final AuthTokenProvider? _tokenProvider;
  AuthRefreshHandler? _authRefreshHandler;

  ApiConfig get config => _config;

  void attachAuthRefreshHandler(AuthRefreshHandler handler) {
    _authRefreshHandler = handler;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Map<String, String> headers = const {},
    bool requiresAuth = false,
    Duration? timeout,
    ResponseDecoder<T>? decoder,
  }) {
    return send<T>(
      ApiRequest(
        path: path,
        method: ApiMethod.get,
        queryParameters: queryParameters,
        headers: headers,
        requiresAuth: requiresAuth,
        timeout: timeout,
      ),
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Map<String, String> headers = const {},
    Object? body,
    bool requiresAuth = false,
    Duration? timeout,
    ResponseDecoder<T>? decoder,
  }) {
    return send<T>(
      ApiRequest(
        path: path,
        method: ApiMethod.post,
        queryParameters: queryParameters,
        headers: headers,
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
      ),
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Map<String, String> headers = const {},
    Object? body,
    bool requiresAuth = false,
    Duration? timeout,
    ResponseDecoder<T>? decoder,
  }) {
    return send<T>(
      ApiRequest(
        path: path,
        method: ApiMethod.put,
        queryParameters: queryParameters,
        headers: headers,
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
      ),
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Map<String, String> headers = const {},
    Object? body,
    bool requiresAuth = false,
    Duration? timeout,
    ResponseDecoder<T>? decoder,
  }) {
    return send<T>(
      ApiRequest(
        path: path,
        method: ApiMethod.patch,
        queryParameters: queryParameters,
        headers: headers,
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
      ),
      decoder: decoder,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic> queryParameters = const {},
    Map<String, String> headers = const {},
    Object? body,
    bool requiresAuth = false,
    Duration? timeout,
    ResponseDecoder<T>? decoder,
  }) {
    return send<T>(
      ApiRequest(
        path: path,
        method: ApiMethod.delete,
        queryParameters: queryParameters,
        headers: headers,
        body: body,
        requiresAuth: requiresAuth,
        timeout: timeout,
      ),
      decoder: decoder,
    );
  }

  Future<String> uploadFile(
    String path, {
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (!_config.hasBaseUrl) throw Exception('No base URL configured');
    final token = await _tokenProvider?.call();
    final uri = Uri.parse('${_config.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Upload failed: ${streamed.statusCode}');
    }
    // response body: {"data":{"message":"/uploads/filename.jpg"}}
    final decoded = jsonDecode(body);
    final msg = (decoded['data']?['message'] ?? decoded['message'] ?? '').toString();
    return msg;
  }

  Future<ApiResponse<T>> send<T>(
    ApiRequest request, {
    ResponseDecoder<T>? decoder,
  }) async {
    if (!_config.hasBaseUrl) {
      throw const ApiException(
        message: 'API_BASE_URL is missing. Pass it with --dart-define.',
        code: 'missing_base_url',
      );
    }

    final uri = _buildUri(request.path, request.queryParameters);
    final headers = await _buildHeaders(request);
    final body = _encodeBody(request.body);
    final timeout = request.timeout ?? _config.receiveTimeout;

    try {
      _logCurlRequest(
        method: request.method,
        uri: uri,
        headers: headers,
        body: body,
      );

      final httpResponse = await _dispatch(
        uri: uri,
        method: request.method,
        headers: headers,
        body: body,
      ).timeout(timeout);

      if (request.requiresAuth &&
          httpResponse.statusCode == 401 &&
          _authRefreshHandler != null) {
        final refreshed = await _authRefreshHandler!.call();
        if (refreshed) {
          final refreshedHeaders = await _buildHeaders(request);
          final retried = await _dispatch(
            uri: uri,
            method: request.method,
            headers: refreshedHeaders,
            body: body,
          ).timeout(timeout);
          final retriedPayload = _decodeBody(retried.body);
          if (!_isSuccess(retried.statusCode)) {
            throw _mapHttpError(retried.statusCode, retriedPayload);
          }
          final retriedData =
              decoder != null ? decoder(retriedPayload) : retriedPayload as T;
          return ApiResponse<T>(
            data: retriedData,
            statusCode: retried.statusCode,
            headers: retried.headers,
          );
        }
      }

      final payload = _decodeBody(httpResponse.body);
      if (!_isSuccess(httpResponse.statusCode)) {
        throw _mapHttpError(httpResponse.statusCode, payload);
      }

      final data = decoder != null ? decoder(payload) : payload as T;
      return ApiResponse<T>(
        data: data,
        statusCode: httpResponse.statusCode,
        headers: httpResponse.headers,
      );
    } on TimeoutException catch (error) {
      throw ApiException(
        message: 'Request timeout',
        code: 'timeout',
        details: error,
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'Network request failed',
        code: 'network_error',
        details: error,
      );
    }
  }

  void close() {
    _httpClient.close();
  }

  Uri _buildUri(String path, Map<String, dynamic> queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse(_config.baseUrl);
    final mergedPath = '${baseUri.path}$normalizedPath'.replaceAll('//', '/');
    final sanitizedQuery = <String, String>{};

    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      sanitizedQuery[entry.key] = value.toString();
    }

    return baseUri.replace(
      path: mergedPath,
      queryParameters: sanitizedQuery.isEmpty ? null : sanitizedQuery,
    );
  }

  Future<Map<String, String>> _buildHeaders(ApiRequest request) async {
    final headers = <String, String>{
      ..._config.defaultHeaders,
      ...request.headers,
    };

    if (request.requiresAuth) {
      final token = await _tokenProvider?.call();
      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          message: 'Access token is missing',
          code: 'missing_token',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> _dispatch({
    required Uri uri,
    required ApiMethod method,
    required Map<String, String> headers,
    required String? body,
  }) {
    switch (method) {
      case ApiMethod.get:
        return _httpClient.get(uri, headers: headers);
      case ApiMethod.post:
        return _httpClient.post(uri, headers: headers, body: body);
      case ApiMethod.put:
        return _httpClient.put(uri, headers: headers, body: body);
      case ApiMethod.patch:
        return _httpClient.patch(uri, headers: headers, body: body);
      case ApiMethod.delete:
        return _httpClient.delete(uri, headers: headers, body: body);
    }
  }

  void _logCurlRequest({
    required ApiMethod method,
    required Uri uri,
    required Map<String, String> headers,
    required String? body,
  }) {
    final buffer = StringBuffer('curl');
    buffer.write(' -X ${method.name.toUpperCase()}');

    for (final entry in headers.entries) {
      buffer.write(" -H '${_escapeForSingleQuotes('${entry.key}: ${entry.value}')}'");
    }

    if (body != null && body.isNotEmpty) {
      buffer.write(" --data-raw '${_escapeForSingleQuotes(body)}'");
    }

    buffer.write(" '${_escapeForSingleQuotes(uri.toString())}'");
    debugPrint('[ApiClient] ${buffer.toString()}');
  }

  String _escapeForSingleQuotes(String value) {
    return value.replaceAll("'", "'\"'\"'");
  }

  String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }
    if (body is String) {
      return body;
    }
    return jsonEncode(body);
  }

  Object? _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  ApiException _mapHttpError(int statusCode, Object? payload) {
    final message = _extractMessage(payload) ?? 'Request failed';
    return ApiException(
      message: message,
      statusCode: statusCode,
      code: _extractCode(payload),
      details: payload,
    );
  }

  String? _extractMessage(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final dynamic message =
          payload['message'] ?? payload['error'] ?? payload['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }
    return null;
  }

  String? _extractCode(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final dynamic code = payload['code'];
      if (code is String && code.trim().isNotEmpty) {
        return code;
      }
    }
    return null;
  }
}
