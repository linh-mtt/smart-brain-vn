/// Input validators for form fields.
///
/// All validators return null for valid input or an error message string
/// for invalid input, following Flutter's [FormField] convention.
abstract final class Validators {
  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates a password.
  ///
  /// Requirements:
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter
  /// - At least 1 number
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least 1 uppercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least 1 number';
    }

    return null;
  }

  /// Validates that a confirm password matches the original.
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != password) {
        return 'Passwords don\'t match';
      }
      return null;
    };
  }

  /// Validates a username.
  ///
  /// Requirements:
  /// - 3-20 characters
  /// - Alphanumeric and underscores only
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 20) {
      return 'Username must be 20 characters or less';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  /// Validates that a field is not empty.
  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates an age value (must be between 5 and 18).
  static String? age(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your age';
    }

    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid number';
    }

    if (age < 5 || age > 18) {
      return 'Age must be between 5 and 18';
    }

    return null;
  }

  /// Validates a grade level (1-6).
  static String? gradeLevel(int? value) {
    if (value == null) {
      return 'Please select a grade level';
    }

    if (value < 1 || value > 6) {
      return 'Grade level must be between 1 and 6';
    }

    return null;
  }
}
