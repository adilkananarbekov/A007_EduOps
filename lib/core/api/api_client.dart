import 'dart:convert';
import 'dart:async' as async;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';
import 'api_exception.dart';

/// HTTP client wrapper for making API requests with error handling
class ApiClient {
  final http.Client _client;
  String? _authToken;
  Future<void> Function()? _onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Set authentication token for subsequent requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get current authentication token
  String? get authToken => _authToken;

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Register a global unauthorized callback (e.g. token expired)
  void setUnauthorizedHandler(Future<void> Function()? handler) {
    _onUnauthorized = handler;
  }

  /// Build headers for requests
  Map<String, String> _buildHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
    };

    if (includeAuth && _authToken != null) {
      headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$_authToken';
    }

    return headers;
  }

  /// Build full URL with base API URL
  String _buildUrl(String endpoint) {
    return '${ApiConstants.baseApiUrl}$endpoint';
  }

  /// Handle HTTP response and throw appropriate exceptions
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    debugPrint(
      '[API] Response: $statusCode ${response.request?.method} ${response.request?.url}',
    );

    // Success responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        debugPrint('[API] Body: (empty)');
        return null;
      }
      try {
        final decoded = json.decode(response.body);
        // Print a truncated version of the response for debugging
        final preview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        debugPrint('[API] Body: $preview');
        return decoded;
      } catch (e) {
        debugPrint('[API] PARSE ERROR: $e');
        debugPrint(
          '[API] Raw body: ${response.body.substring(0, response.body.length.clamp(0, 500))}',
        );
        throw ParseException(
          'Failed to parse response: ${e.toString()}',
          originalError: e,
        );
      }
    }

    // Error responses
    debugPrint(
      '[API] ERROR $statusCode: ${response.body.substring(0, response.body.length.clamp(0, 1000))}',
    );
    String errorMessage = 'Request failed with status $statusCode';
    try {
      final errorBody = json.decode(response.body);
      if (errorBody is Map<String, dynamic>) {
        errorMessage =
            errorBody['message'] ??
            errorBody['error'] ??
            errorBody['detail'] ??
            errorMessage;
      }
    } catch (e) {
      // If we can't parse the error body, use the default message
      errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
    }

    switch (statusCode) {
      case 400:
        throw ValidationException(errorMessage, statusCode: statusCode);
      case 401:
        _onUnauthorized?.call();
        throw UnauthorizedException(errorMessage, statusCode: statusCode);
      case 403:
        throw ForbiddenException(errorMessage, statusCode: statusCode);
      case 404:
        throw NotFoundException(errorMessage, statusCode: statusCode);
      case >= 500:
        throw ServerException(errorMessage, statusCode: statusCode);
      default:
        throw UnknownException(errorMessage);
    }
  }

  /// Make GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var url = _buildUrl(endpoint);
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      debugPrint('[API] GET $url');
      debugPrint(
        '[API] Token: ${_authToken != null ? '${_authToken!.substring(0, 20)}...' : 'null'}',
      );
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders(includeAuth: includeAuth))
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API] GET SocketException: $e');
      throw NetworkException(
        'No internet connection. Please check your network.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      debugPrint('[API] GET ClientException: $e');
      throw NetworkException(
        'Network request failed: ${e.message}',
        originalError: e,
      );
    } on async.TimeoutException catch (e) {
      debugPrint('[API] GET Timeout: $e');
      throw ApiTimeoutException(
        'Request timed out. Please try again.',
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] GET Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Make POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var url = _buildUrl(endpoint);
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      debugPrint('[API] POST $url');
      debugPrint(
        '[API] POST body: ${body != null ? json.encode(body) : 'null'}',
      );
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _buildHeaders(includeAuth: includeAuth),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API] POST SocketException: $e');
      throw NetworkException(
        'No internet connection. Please check your network.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      debugPrint('[API] POST ClientException: $e');
      throw NetworkException(
        'Network request failed: ${e.message}',
        originalError: e,
      );
    } on async.TimeoutException catch (e) {
      debugPrint('[API] POST Timeout: $e');
      throw ApiTimeoutException(
        'Request timed out. Please try again.',
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] POST Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Make PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      debugPrint('[API] PUT $url');
      debugPrint(
        '[API] PUT body: ${body != null ? json.encode(body) : 'null'}',
      );
      final response = await _client
          .put(
            Uri.parse(url),
            headers: _buildHeaders(includeAuth: includeAuth),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API] PUT SocketException: $e');
      throw NetworkException(
        'No internet connection. Please check your network.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      debugPrint('[API] PUT ClientException: $e');
      throw NetworkException(
        'Network request failed: ${e.message}',
        originalError: e,
      );
    } on async.TimeoutException catch (e) {
      debugPrint('[API] PUT Timeout: $e');
      throw ApiTimeoutException(
        'Request timed out. Please try again.',
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] PUT Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Make DELETE request
  Future<dynamic> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final url = _buildUrl(endpoint);
      debugPrint('[API] DELETE $url');
      final response = await _client
          .delete(
            Uri.parse(url),
            headers: _buildHeaders(includeAuth: includeAuth),
          )
          .timeout(ApiConstants.connectionTimeout);

      return _handleResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API] DELETE SocketException: $e');
      throw NetworkException(
        'No internet connection. Please check your network.',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      debugPrint('[API] DELETE ClientException: $e');
      throw NetworkException(
        'Network request failed: ${e.message}',
        originalError: e,
      );
    } on async.TimeoutException catch (e) {
      debugPrint('[API] DELETE Timeout: $e');
      throw ApiTimeoutException(
        'Request timed out. Please try again.',
        originalError: e,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] DELETE Unknown error: $e');
      throw UnknownException(
        'Unexpected error: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
