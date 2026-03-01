import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Interceptor for logging HTTP requests and responses in debug mode.
///
/// Uses the [Logger] package for formatted, readable output.
class AppLoggingInterceptor extends Interceptor {
  AppLoggingInterceptor()
    : _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 80,
          noBoxingByDefault: true,
        ),
      );

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i(
        '┌── REQUEST ──────────────────────────────────────\n'
        '│ ${options.method} ${options.uri}\n'
        '│ Headers: ${_sanitizeHeaders(options.headers)}\n'
        '│ Data: ${_truncateData(options.data)}\n'
        '└─────────────────────────────────────────────────',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      _logger.d(
        '┌── RESPONSE ─────────────────────────────────────\n'
        '│ ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}\n'
        '│ Data: ${_truncateData(response.data)}\n'
        '└─────────────────────────────────────────────────',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e(
        '┌── ERROR ────────────────────────────────────────\n'
        '│ ${err.response?.statusCode ?? "?"} ${err.requestOptions.method} '
        '${err.requestOptions.uri}\n'
        '│ Type: ${err.type}\n'
        '│ Message: ${err.message}\n'
        '│ Response: ${_truncateData(err.response?.data)}\n'
        '└─────────────────────────────────────────────────',
      );
    }
    handler.next(err);
  }

  /// Sanitizes headers to avoid logging sensitive information.
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'] as String?;
      if (auth != null && auth.length > 20) {
        sanitized['Authorization'] = '${auth.substring(0, 15)}...';
      }
    }
    return sanitized;
  }

  /// Truncates response data for readable logging.
  String _truncateData(dynamic data) {
    if (data == null) return 'null';
    final str = data.toString();
    if (str.length > 500) {
      return '${str.substring(0, 500)}... [truncated]';
    }
    return str;
  }
}
