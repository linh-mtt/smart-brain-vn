import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/exceptions.dart';
import '../errors/failures.dart';
import 'dio_provider.dart';

/// Typed API client that wraps [Dio] with error handling.
///
/// Provides generic HTTP methods that automatically map errors
/// to application-specific [Failure] types.
class ApiClient {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Performs a GET request.
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _parseResponse(response, fromJson);
    });
  }

  /// Performs a POST request.
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _parseResponse(response, fromJson);
    });
  }

  /// Performs a PUT request.
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _parseResponse(response, fromJson);
    });
  }

  /// Performs a PATCH request.
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _parseResponse(response, fromJson);
    });
  }

  /// Performs a DELETE request.
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _handleRequest(() async {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _parseResponse(response, fromJson);
    });
  }

  /// Parses the response data using the provided [fromJson] function.
  T _parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic)? fromJson,
  ) {
    if (fromJson != null) {
      return fromJson(response.data);
    }
    return response.data as T;
  }

  /// Handles request execution with error mapping.
  Future<T> _handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on SocketException {
      throw const NetworkException();
    }
  }

  /// Maps [DioException] to application-specific exceptions.
  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Could not connect to the server.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message = _extractErrorMessage(data);

        if (statusCode == 401) {
          return AuthException(
            message: message ?? 'Session expired. Please log in again.',
            statusCode: statusCode,
          );
        }
        if (statusCode == 403) {
          return AuthException(
            message: message ?? 'You don\'t have permission to do that.',
            statusCode: statusCode,
          );
        }
        return ServerException(
          message: message ?? 'Something went wrong on our end.',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const ServerException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const ServerException(
          message: 'Certificate verification failed.',
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkException();
        }
        return ServerException(
          message: error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  /// Extracts error message from API response data.
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['errors']?.toString();
    }
    if (data is String && data.isNotEmpty) {
      return data;
    }
    return null;
  }
}

/// Maps [AppException] to [Failure] for use in the domain layer.
Failure mapExceptionToFailure(AppException exception) {
  return switch (exception) {
    ServerException(:final message, :final statusCode) => ServerFailure(
      message: message,
      statusCode: statusCode,
    ),
    CacheException(:final message, :final statusCode) => CacheFailure(
      message: message,
      statusCode: statusCode,
    ),
    NetworkException(:final message, :final statusCode) => NetworkFailure(
      message: message,
      statusCode: statusCode,
    ),
    AuthException(:final message, :final statusCode) => AuthFailure(
      message: message,
      statusCode: statusCode,
    ),
    TokenExpiredException(:final message, :final statusCode) => AuthFailure(
      message: message,
      statusCode: statusCode,
    ),
  };
}

/// Riverpod provider for [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.read(dioProvider);
  return ApiClient(dio: dio);
});
