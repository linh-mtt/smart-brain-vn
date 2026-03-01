import 'package:intl/intl.dart';

/// Utility formatters for display values.
abstract final class Formatters {
  /// Formats a number with comma separators.
  /// Example: 1000 → "1,000"
  static String formatPoints(int points) {
    return NumberFormat('#,###').format(points);
  }

  /// Formats a duration into a human-readable string.
  /// Example: Duration(minutes: 125) → "2h 5m"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Formats a duration in seconds to mm:ss format.
  /// Example: 125 → "02:05"
  static String formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats a DateTime to a readable date string.
  /// Example: DateTime(2024, 1, 15) → "Jan 15, 2024"
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Formats a DateTime to a readable date-time string.
  /// Example: DateTime(2024, 1, 15, 14, 30) → "Jan 15, 2024 at 2:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(dateTime);
  }

  /// Formats a DateTime to a relative time string.
  /// Example: "Just now", "5 minutes ago", "2 hours ago", "Yesterday"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return formatDate(dateTime);
  }

  /// Formats a decimal as a percentage string.
  /// Example: 0.856 → "85.6%"
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Formats a large number with abbreviation.
  /// Example: 1500 → "1.5K", 1500000 → "1.5M"
  static String formatCompactNumber(int number) {
    return NumberFormat.compact().format(number);
  }

  /// Formats an ordinal number.
  /// Example: 1 → "1st", 2 → "2nd", 3 → "3rd", 4 → "4th"
  static String formatOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    return switch (number % 10) {
      1 => '${number}st',
      2 => '${number}nd',
      3 => '${number}rd',
      _ => '${number}th',
    };
  }
}
