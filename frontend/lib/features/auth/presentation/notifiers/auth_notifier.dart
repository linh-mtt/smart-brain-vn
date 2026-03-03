import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

/// Manages authentication state for the entire application.
///
/// Provides methods for login, registration, logout, and profile management.
/// The state is [AsyncValue<UserModel?>] where null means not authenticated.
class AuthNotifier extends AsyncNotifier<UserModel?> {
  late AuthRepository _repository;

  @override
  FutureOr<UserModel?> build() {
    _repository = ref.read(authRepositoryProvider);
    return null;
  }

  /// Checks if the user has valid stored credentials.
  ///
  /// Called on app startup to determine initial auth state.
  Future<void> checkAuthStatus() async {
    state = const AsyncValue.loading();

    final result = await _repository.checkAuthStatus();
    state = result.fold(
      onSuccess: (user) => AsyncValue.data(
        UserModel(
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          gradeLevel: user.gradeLevel,
          role: user.role,
        ),
      ),
      onFailure: (_) => const AsyncValue.data(null),
    );
  }

  /// Logs in with email and password.
  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    final result = await _repository.login(email: email, password: password);

    state = result.fold(
      onSuccess: (authResponse) => AsyncValue.data(
        UserModel(
          id: authResponse.user.id,
          email: authResponse.user.email,
          username: authResponse.user.username,
          displayName: authResponse.user.displayName,
          avatarUrl: authResponse.user.avatarUrl,
          gradeLevel: authResponse.user.gradeLevel,
          role: authResponse.user.role,
        ),
      ),
      onFailure: (failure) => AsyncValue.error(failure, StackTrace.current),
    );
  }

  /// Logs in with Google ID Token.
  Future<void> googleLogin({required String idToken}) async {
    state = const AsyncValue.loading();

    final result = await _repository.googleLogin(idToken: idToken);

    state = result.fold(
      onSuccess: (authResponse) => AsyncValue.data(
        UserModel(
          id: authResponse.user.id,
          email: authResponse.user.email,
          username: authResponse.user.username,
          displayName: authResponse.user.displayName,
          avatarUrl: authResponse.user.avatarUrl,
          gradeLevel: authResponse.user.gradeLevel,
          role: authResponse.user.role,
        ),
      ),
      onFailure: (failure) => AsyncValue.error(failure, StackTrace.current),
    );
  }

  /// Registers a new user account.
  Future<void> register({
    required String email,
    required String username,
    required String password,
    required int gradeLevel,
    required int age,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repository.register(
      email: email,
      username: username,
      password: password,
      gradeLevel: gradeLevel,
      age: age,
    );

    state = result.fold(
      onSuccess: (authResponse) => AsyncValue.data(
        UserModel(
          id: authResponse.user.id,
          email: authResponse.user.email,
          username: authResponse.user.username,
          displayName: authResponse.user.displayName,
          avatarUrl: authResponse.user.avatarUrl,
          gradeLevel: authResponse.user.gradeLevel,
          role: authResponse.user.role,
        ),
      ),
      onFailure: (failure) => AsyncValue.error(failure, StackTrace.current),
    );
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  /// Refreshes the user's profile data from the server.
  Future<void> refreshProfile() async {
    final result = await _repository.getProfile();
    result.fold(
      onSuccess: (user) {
        state = AsyncValue.data(
          UserModel(
            id: user.id,
            email: user.email,
            username: user.username,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            gradeLevel: user.gradeLevel,
            role: user.role,
          ),
        );
      },
      onFailure: (_) {
        // Keep current state on refresh failure
      },
    );
  }

  /// Updates the user's profile.
  Future<void> updateProfile({String? displayName, int? gradeLevel}) async {
    final previousState = state;

    final result = await _repository.updateProfile(
      displayName: displayName,
      gradeLevel: gradeLevel,
    );

    state = result.fold(
      onSuccess: (user) => AsyncValue.data(
        UserModel(
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          gradeLevel: user.gradeLevel,
          role: user.role,
        ),
      ),
      onFailure: (failure) {
        // Revert to previous state on failure
        state = previousState;
        return AsyncValue.error(failure, StackTrace.current);
      },
    );
  }
}

/// The main auth state provider.
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  () {
    return AuthNotifier();
  },
);
