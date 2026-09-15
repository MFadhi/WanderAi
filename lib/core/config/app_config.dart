/// WanderAI Application Configuration
///
/// Replace placeholder values with your actual API keys.
/// See API_SETUP.md for step-by-step instructions.
class AppConfig {
  AppConfig._();

  // ─────────────────────────────────────────────
  // API Keys — Replace with your actual keys
  // ─────────────────────────────────────────────

  /// Google Maps Platform API Key
  /// Enable: Maps SDK for iOS, Places API (New), Routes API
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: 'AIzaSyCHerwqqt4bNVbF_G3V-a4vgdosC-KV-sg');

  /// Google Gemini API Key
  /// Get from: https://aistudio.google.com/app/apikey
  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_GEMINI_API_KEY');

  // ─────────────────────────────────────────────
  // Service Capability Flags
  // ─────────────────────────────────────────────

  static bool get hasGoogleMapsKey =>
      googleMapsApiKey.isNotEmpty &&
      googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  static bool get hasGeminiKey =>
      geminiApiKey.isNotEmpty &&
      geminiApiKey != 'YOUR_GEMINI_API_KEY';

  /// Live Google Map is shown whenever a Google Maps API key is configured.
  static bool get useLiveMap => hasGoogleMapsKey;

  /// Whether Places API uses live Google Places or fallback mock data.
  static bool get useMockPlaces => !hasGoogleMapsKey;

  /// Whether AI features use live Gemini API or simulated response.
  static bool get useMockGemini => !hasGeminiKey;

  /// General fallback mock mode
  static bool get useMockData => !hasGoogleMapsKey;

  // ─────────────────────────────────────────────
  // API Base URLs
  // ─────────────────────────────────────────────

  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.0-flash';

  static const String placesBaseUrl = 'https://places.googleapis.com/v1';

  static const String routesBaseUrl = 'https://routes.googleapis.com';

  // ─────────────────────────────────────────────
  // Search Defaults
  // ─────────────────────────────────────────────

  /// Default search radius in metres
  static const double defaultSearchRadius = 5000.0;
  static const int maxNearbyResults = 20;
  static const int maxReviewsPerPlace = 5;
  static const int maxPhotosPerPlace = 3;

  /// Default location fallback (Kannur, Kerala) used when GPS is unavailable
  static const double defaultLat = 11.8745;
  static const double defaultLng = 75.3704;
  static const String defaultCityName = 'Kannur';
}
