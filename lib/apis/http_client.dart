import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Shared HTTP client with timeouts and user-friendly network errors.
class ApiHttp {
  ApiHttp._();

  static const Duration timeout = Duration(seconds: 25);

  static Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    return http.get(uri, headers: headers).timeout(timeout, onTimeout: _onTimeout);
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return http
        .post(uri, headers: headers, body: body)
        .timeout(timeout, onTimeout: _onTimeout);
  }

  static Future<http.Response> _onTimeout() {
    throw ApiException('Cannot reach server. Check your connection and try again.');
  }

  static Map<String, dynamic> decodeJsonMap(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw ApiException('Unexpected server response.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected server response.');
    }
  }

  static Never rethrowAsApiException(Object error) {
    if (error is ApiException) throw error;
    if (error is TimeoutException) {
      throw ApiException('Request timed out. Check your connection and try again.');
    }
    if (error is SocketException) {
      throw ApiException('Cannot reach server. Check your connection and try again.');
    }
    if (error is HttpException) {
      throw ApiException('Network error. Please try again.');
    }
    throw ApiException(error.toString().replaceFirst('Exception: ', ''));
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
