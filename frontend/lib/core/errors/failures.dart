/// Sealed class representing the result of an operation.
///
/// Use [Result.success] for successful operations and [Result.failure] for failures.
sealed class Result<T> {
  const Result();

  /// Creates a successful result with the given [data].
  const factory Result.success(T data) = Success<T>;

  /// Creates a failed result with the given [failure].
  const factory Result.failure(Failure failure) = Err<T>;

  /// Returns `true` if this is a successful result.
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a failed result.
  bool get isFailure => this is Err<T>;

  /// Maps the success value to a new type.
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Result.success(transform(data)),
      Err<T>(:final failure) => Result.failure(failure),
    };
  }

  /// Flat-maps the success value to a new Result.
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => transform(data),
      Err<T>(:final failure) => Result.failure(failure),
    };
  }

  /// Folds the result into a single value.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final data) => onSuccess(data),
      Err<T>(:final failure) => onFailure(failure),
    };
  }

  /// Returns the success value or null.
  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Err<T>() => null,
  };

  /// Returns the failure or null.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };
}

/// Represents a successful result.
final class Success<T> extends Result<T> {
  const Success(this.data);

  /// The success data.
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result.
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// The failure details.
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}

/// Sealed class representing different types of failures.
sealed class Failure {
  const Failure({required this.message, this.statusCode});

  /// Human-readable error message.
  final String message;

  /// Optional HTTP status code.
  final int? statusCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(message, statusCode);

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode)';

  /// Returns a user-friendly error message suitable for display.
  String get displayMessage => switch (this) {
    ServerFailure() => 'Oops! Our server had a hiccup. Let\'s try again!',
    CacheFailure() => 'Oops! We couldn\'t save that. Let\'s try again!',
    NetworkFailure() =>
      'No internet connection! Check your WiFi and try again.',
    AuthFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    UnknownFailure() => 'Something went wrong. Let\'s try again!',
  };
}

/// Server-related failure (5xx errors, timeouts, etc.).
final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Local cache/storage failure.
final class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

/// Network connectivity failure.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.statusCode,
  });
}

/// Authentication/authorization failure.
final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.statusCode});
}

/// Input validation failure.
final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode});
}

/// Unknown/unhandled failure.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.statusCode,
  });
}
