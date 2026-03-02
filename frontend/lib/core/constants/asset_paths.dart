/// Asset file path constants.
///
/// Centralizes all asset paths to prevent typos and make refactoring easy.
abstract final class AssetPaths {
  // ─── Base Directories ─────────────────────────────────────────────

  static const String _animations = 'assets/animations';
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';

  // ─── Animations (Lottie/Rive) ─────────────────────────────────────

  static const String splashAnimation = '$_animations/splash.json';
  static const String loadingAnimation = '$_animations/loading.json';
  static const String successAnimation = '$_animations/success.json';
  static const String celebrationAnimation = '$_animations/celebration.json';
  static const String thinkingAnimation = '$_animations/thinking.json';
  static const String streakAnimation = '$_animations/streak.json';

  // ─── Learning Tips Animations ──────────────────────────────────

  static const String tipAdditionAnimation = '$_animations/tip_addition.json';
  static const String tipMultiplicationAnimation =
      '$_animations/tip_multiplication.json';
  static const String tipMentalMathAnimation =
      '$_animations/tip_mental_math.json';
  static const String quizSuccessAnimation = '$_animations/quiz_success.json';

  // ─── Competition Animations ───────────────────────────────────────

  static const String countdownAnimation = '$_animations/countdown.json';
  static const String victoryAnimation = '$_animations/victory.json';
  static const String defeatAnimation = '$_animations/defeat.json';
  static const String matchFoundAnimation = '$_animations/match_found.json';
  static const String battleAnimation = '$_animations/battle.json';

  // ─── Images ───────────────────────────────────────────────────────

  static const String logoImage = '$_images/logo.png';
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';
  static const String emptyState = '$_images/empty_state.png';
  static const String errorImage = '$_images/error.png';
  static const String mathBackground = '$_images/math_bg.png';

  // ─── Icons ────────────────────────────────────────────────────────

  static const String googleIcon = '$_icons/google.svg';
  static const String appleIcon = '$_icons/apple.svg';
  static const String additionIcon = '$_icons/addition.svg';
  static const String subtractionIcon = '$_icons/subtraction.svg';
  static const String multiplicationIcon = '$_icons/multiplication.svg';
  static const String divisionIcon = '$_icons/division.svg';
  static const String starIcon = '$_icons/star.svg';
  static const String trophyIcon = '$_icons/trophy.svg';
  static const String streakIcon = '$_icons/streak.svg';
}
