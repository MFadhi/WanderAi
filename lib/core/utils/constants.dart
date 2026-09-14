/// Application-wide constants
sealed class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────
  // Spacing
  // ─────────────────────────────────────────────
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  static const double space3XL = 64.0;

  // ─────────────────────────────────────────────
  // Border Radius
  // ─────────────────────────────────────────────
  static const double radiusXS = 6.0;
  static const double radiusSM = 10.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;
  static const double radiusFull = 100.0;

  // ─────────────────────────────────────────────
  // Animation Durations
  // ─────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animVerySlow = Duration(milliseconds: 800);

  // ─────────────────────────────────────────────
  // Explore Categories
  // ─────────────────────────────────────────────
  static const List<String> categories = [
    'Food',
    'Cafés',
    'Nature',
    'History',
    'Photography',
    'Shopping',
    'Adventure',
    'Culture',
  ];

  static const Map<String, String> categoryEmojis = {
    'Food': '🍛',
    'Cafés': '☕',
    'Nature': '🌿',
    'History': '🏛️',
    'Photography': '📸',
    'Shopping': '🛍️',
    'Adventure': '🎯',
    'Culture': '🎭',
  };

  static const Map<String, String> categoryTypes = {
    'Food': 'restaurant',
    'Cafés': 'cafe',
    'Nature': 'park',
    'History': 'tourist_attraction',
    'Photography': 'scenic_lookout',
    'Shopping': 'shopping_mall',
    'Adventure': 'tourist_attraction',
    'Culture': 'museum',
  };

  // ─────────────────────────────────────────────
  // Transport
  // ─────────────────────────────────────────────
  static const Map<String, String> transportEmojis = {
    'WALK': '🚶',
    'BICYCLE': '🚲',
    'TWO_WHEELER': '🛵',
    'DRIVE': '🚗',
    'TRANSIT': '🚌',
    'TAXI': '🚕',
  };

  static const Map<String, String> transportLabels = {
    'WALK': 'Walking',
    'BICYCLE': 'Bicycle',
    'TWO_WHEELER': 'Two-wheeler',
    'DRIVE': 'Car',
    'TRANSIT': 'Public transport',
    'TAXI': 'Taxi',
  };

  // ─────────────────────────────────────────────
  // Duration options for trip planner
  // ─────────────────────────────────────────────
  static const List<String> tripDurations = [
    '2 Hours',
    'Half Day',
    'Full Day',
    'Multiple Days',
  ];

  static const Map<String, double> tripDurationHours = {
    '2 Hours': 2.0,
    'Half Day': 4.0,
    'Full Day': 8.0,
    'Multiple Days': 24.0,
  };

  // ─────────────────────────────────────────────
  // Budget Ranges (INR)
  // ─────────────────────────────────────────────
  static const List<String> budgetOptions = [
    'Free',
    '₹500',
    '₹1,000',
    '₹2,000',
    'Custom',
  ];

  static const Map<String, double> budgetValues = {
    'Free': 0,
    '₹500': 500,
    '₹1,000': 1000,
    '₹2,000': 2000,
    'Custom': -1,
  };

  // ─────────────────────────────────────────────
  // Travel styles
  // ─────────────────────────────────────────────
  static const List<String> travelStyles = [
    'Relaxed',
    'Balanced',
    'Fast-paced',
  ];

  static const Map<String, String> travelStyleEmojis = {
    'Relaxed': '🌸',
    'Balanced': '⚖️',
    'Fast-paced': '⚡',
  };

  // ─────────────────────────────────────────────
  // SharedPreferences Keys
  // ─────────────────────────────────────────────
  static const String prefKeyPreferences = 'user_preferences';
  static const String prefKeySavedPlaces = 'saved_places';
  static const String prefKeyOnboardingDone = 'onboarding_done';

  // ─────────────────────────────────────────────
  // Assets
  // ─────────────────────────────────────────────
  static const String assetsImages = 'assets/images/';
  static const String assetsMock = 'assets/mock/';
}
