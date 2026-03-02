import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/xp_profile_entity.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../providers/gamification_providers.dart';

/// State for the gamification feature.
class GamificationState {
  const GamificationState({
    this.profile,
    this.themes = const [],
    this.isLoading = false,
    this.isLoadingThemes = false,
    this.error,
  });

  /// The user's XP profile.
  final XpProfileEntity? profile;

  /// Available themes with unlock status.
  final List<ThemeEntity> themes;

  /// Whether profile data is being loaded.
  final bool isLoading;

  /// Whether theme data is being loaded.
  final bool isLoadingThemes;

  /// Error message if loading failed.
  final String? error;

  /// Whether profile data has been loaded.
  bool get hasData => profile != null;

  /// Creates a copy with modified fields.
  GamificationState copyWith({
    XpProfileEntity? profile,
    List<ThemeEntity>? themes,
    bool? isLoading,
    bool? isLoadingThemes,
    String? error,
  }) {
    return GamificationState(
      profile: profile ?? this.profile,
      themes: themes ?? this.themes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingThemes: isLoadingThemes ?? this.isLoadingThemes,
      error: error,
    );
  }
}

/// Manages gamification state (XP profile, themes, achievements).
///
/// Provides methods to load and refresh gamification data.
class GamificationNotifier extends Notifier<GamificationState> {
  late GamificationRepository _repository;

  @override
  GamificationState build() {
    _repository = ref.read(gamificationRepositoryProvider);
    return const GamificationState();
  }

  /// Loads the user's XP profile.
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getXpProfile();
    result.fold(
      onSuccess: (profile) =>
          state = state.copyWith(profile: profile, isLoading: false),
      onFailure: (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.displayMessage,
      ),
    );
  }

  /// Loads all available themes.
  Future<void> loadThemes() async {
    state = state.copyWith(isLoadingThemes: true);

    final result = await _repository.getThemes();
    result.fold(
      onSuccess: (themes) =>
          state = state.copyWith(themes: themes, isLoadingThemes: false),
      onFailure: (failure) => state = state.copyWith(
        isLoadingThemes: false,
        error: failure.displayMessage,
      ),
    );
  }

  /// Unlocks a theme and refreshes data.
  Future<void> unlockTheme(String themeId) async {
    final result = await _repository.unlockTheme(themeId);
    result.fold(
      onSuccess: (_) {
        loadThemes();
        loadProfile();
      },
      onFailure: (failure) =>
          state = state.copyWith(error: failure.displayMessage),
    );
  }

  /// Activates a theme and refreshes data.
  Future<void> activateTheme(String themeId) async {
    final result = await _repository.activateTheme(themeId);
    result.fold(
      onSuccess: (_) {
        loadThemes();
        loadProfile();
      },
      onFailure: (failure) =>
          state = state.copyWith(error: failure.displayMessage),
    );
  }

  /// Refreshes all gamification data.
  Future<void> refresh() async {
    await Future.wait([loadProfile(), loadThemes()]);
  }
}
