/// Custom exception types for WanderAI
library;

// ─────────────────────────────────────────────
// Network & Server
// ─────────────────────────────────────────────

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

// ─────────────────────────────────────────────
// Location
// ─────────────────────────────────────────────

class LocationException implements Exception {
  final String message;
  final LocationFailureReason reason;

  const LocationException({
    required this.message,
    this.reason = LocationFailureReason.unknown,
  });

  @override
  String toString() => 'LocationException(${reason.name}): $message';
}

enum LocationFailureReason {
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  timeout,
  unknown,
}

// ─────────────────────────────────────────────
// AI / Gemini
// ─────────────────────────────────────────────

class GeminiException implements Exception {
  final String message;

  const GeminiException({required this.message});

  @override
  String toString() => 'GeminiException: $message';
}

class JsonParseException implements Exception {
  final String message;
  final String? rawContent;

  const JsonParseException({required this.message, this.rawContent});

  @override
  String toString() => 'JsonParseException: $message';
}

// ─────────────────────────────────────────────
// Places
// ─────────────────────────────────────────────

class PlacesException implements Exception {
  final String message;

  const PlacesException({required this.message});

  @override
  String toString() => 'PlacesException: $message';
}

class NoNearbyPlacesException implements Exception {
  final String message;

  const NoNearbyPlacesException({
    this.message = 'No nearby places found. Try expanding your search radius.',
  });

  @override
  String toString() => 'NoNearbyPlacesException: $message';
}
