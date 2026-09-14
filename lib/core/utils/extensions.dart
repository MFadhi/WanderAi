import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isNullOrEmpty => isEmpty;

  /// Truncate with ellipsis
  String truncate(int maxLength) =>
      length > maxLength ? '${substring(0, maxLength)}...' : this;
}

extension DoubleExtensions on double {
  /// Format as INR currency: ₹1,200
  String get inr {
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return fmt.format(this);
  }

  /// Format as compact distance: 1.2 km or 800 m
  String get distanceLabel {
    if (this < 1.0) {
      return '${(this * 1000).round()} m';
    }
    return '${toStringAsFixed(1)} km';
  }
}

extension IntExtensions on int {
  /// Format duration in minutes to readable string: "8 min" or "1 hr 20 min"
  String get minuteLabel {
    if (this < 60) return '$this min';
    final h = this ~/ 60;
    final m = this % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  /// Compact format for large numbers: 1.2k
  String get compact {
    if (this < 1000) return toString();
    if (this < 1000000) return '${(this / 1000).toStringAsFixed(1)}k';
    return '${(this / 1000000).toStringAsFixed(1)}M';
  }
}

extension DateTimeExtensions on DateTime {
  String get timeLabel => DateFormat.jm().format(this);
  String get dateLabel => DateFormat.MMMd().format(this);
  String get fullLabel => DateFormat('MMM d, yyyy – h:mm a').format(this);

  /// e.g. "this morning", "this afternoon", "this evening"
  String get timeOfDay {
    final h = hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    if (h < 21) return 'evening';
    return 'night';
  }

  /// e.g. "Good morning ☀️"
  String get greeting {
    final t = timeOfDay;
    return switch (t) {
      'morning' => 'Good morning ☀️',
      'afternoon' => 'Good afternoon 🌤️',
      'evening' => 'Good evening 🌆',
      _ => 'Good night 🌙',
    };
  }
}

extension ColorExtensions on Color {
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);
}

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
