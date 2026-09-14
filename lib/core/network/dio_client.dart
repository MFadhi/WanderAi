import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';

/// Dio HTTP client with logging and timeout configuration
class DioClient {
  DioClient._();

  static Dio create({
    String? baseUrl,
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      ),
    );

    // Logging interceptor (debug only)
    assert(() {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false, // avoid very large payloads
          logPrint: (obj) => debugPrint('[DIO] $obj'),
        ),
      );
      return true;
    }());

    return dio;
  }

  /// Dio instance pre-configured for Google Places API (New)
  static Dio get places => create(
        baseUrl: AppConfig.placesBaseUrl,
        headers: {'X-Goog-Api-Key': AppConfig.googleMapsApiKey},
      );

  /// Dio instance pre-configured for Gemini REST API
  static Dio get gemini => create(baseUrl: AppConfig.geminiBaseUrl);

  /// Dio instance pre-configured for Google Routes API
  static Dio get routes => create(
        baseUrl: AppConfig.routesBaseUrl,
        headers: {'X-Goog-Api-Key': AppConfig.googleMapsApiKey},
      );
}

// Tiny helper to silence unused import warnings in release builds
void debugPrint(String msg) {
  // ignore: avoid_print
  assert(() {
    print(msg); // ignore: avoid_print
    return true;
  }());
}
