/// Base exception for all app-specific exceptions.
sealed class AppException implements Exception {
  const AppException({required this.message, this.statusCode});

  /// Human-readable error message.
  final String message;

  /// Optional HTTP status code.
  final int? statusCode;

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode)';
}

/// Exception thrown when the server returns an error response.
final class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

/// Exception thrown when a local cache operation fails.
final class CacheException extends AppException {
  const CacheException({required super.message, super.statusCode});
}

/// Exception thrown when there is no network connectivity.
final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.statusCode,
  });
}

/// Exception thrown when authentication fails.
final class AuthException extends AppException {
  const AuthException({required super.message, super.statusCode});
}

/// Exception thrown when token refresh fails.
final class TokenExpiredException extends AppException {
  const TokenExpiredException({
    super.message = 'Session expired. Please log in again.',
    super.statusCode = 401,
  });
}
