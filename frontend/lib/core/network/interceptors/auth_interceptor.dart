import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../errors/exceptions.dart';
import '../../storage/secure_storage_service.dart';

/// Interceptor that handles authentication token injection and refresh.
///
/// Automatically adds the Bearer token to outgoing requests and
/// handles 401 responses by attempting a token refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService secureStorage,
    required Dio dio,
  }) : _secureStorage = secureStorage,
       _dio = dio;

  final SecureStorageService _secureStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login/register/refresh endpoints
    final skipPaths = [
      ApiConstants.loginEndpoint,
      ApiConstants.registerEndpoint,
      ApiConstants.refreshTokenEndpoint,
    ];

    final shouldSkip = skipPaths.any((path) => options.path.contains(path));

    if (!shouldSkip) {
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          await _handleLogout();
          handler.reject(err);
          return;
        }

        // Attempt token refresh
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.apiBasePath,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final response = await refreshDio.post<Map<String, dynamic>>(
          ApiConstants.refreshTokenEndpoint,
          data: {'refreshToken': refreshToken},
        );

        final newAccessToken = response.data?['accessToken'] as String?;
        final newRefreshToken = response.data?['refreshToken'] as String?;

        if (newAccessToken == null) {
          await _handleLogout();
          handler.reject(err);
          return;
        }

        // Save new tokens
        await _secureStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.saveRefreshToken(newRefreshToken);
        }

        // Retry the original request with new token
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await _dio.fetch<dynamic>(options);
        handler.resolve(retryResponse);
      } on DioException {
        await _handleLogout();
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const TokenExpiredException(),
            type: DioExceptionType.badResponse,
            response: err.response,
          ),
        );
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  /// Clears stored tokens on authentication failure.
  Future<void> _handleLogout() async {
    await _secureStorage.deleteTokens();
  }
}
