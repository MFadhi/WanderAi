import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../models/transport_model.dart';

/// Google Routes API service for multi-mode travel time computation.
class RoutesService {
  RoutesService() : _dio = DioClient.routes;

  final Dio _dio;

  static const String _fieldMask =
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline';

  // ─────────────────────────────────────────────
  // Compute Single Route
  // ─────────────────────────────────────────────

  Future<TransportOption?> computeRoute({
    required LatLng origin,
    required LatLng destination,
    required TransportMode mode,
  }) async {
    try {
      final response = await _dio.post(
        '/directions/v2:computeRoutes',
        options: Options(
          headers: {
            'X-Goog-Api-Key': AppConfig.googleMapsApiKey,
            'X-Goog-FieldMask': _fieldMask,
          },
        ),
        data: {
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              },
            },
          },
          'travelMode': mode.apiValue,
          'computeAlternativeRoutes': false,
          'routeModifiers': {
            'avoidTolls': false,
            'avoidHighways': false,
          },
        },
      );

      final routes =
          (response.data['routes'] as List<dynamic>?) ?? [];
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final durationSec =
          int.tryParse(route['duration']?.toString().replaceAll('s', '') ?? '0') ?? 0;
      final distanceM = route['distanceMeters'] as int? ?? 0;

      return TransportOption(
        mode: mode,
        distanceKm: distanceM / 1000.0,
        durationMinutes: (durationSec / 60).ceil(),
      );
    } on DioException {
      return null; // gracefully skip this mode if API fails
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Compute All Modes
  // ─────────────────────────────────────────────

  /// Computes routes for Walk, Two-wheeler, and Drive in parallel.
  /// Falls back to straight-line distance estimates if API fails.
  Future<List<TransportOption>> computeAllRoutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final straightLineKm = _straightLineKm(origin, destination);

    final results = await Future.wait([
      computeRoute(origin: origin, destination: destination, mode: TransportMode.walk),
      computeRoute(origin: origin, destination: destination, mode: TransportMode.twoWheeler),
      computeRoute(origin: origin, destination: destination, mode: TransportMode.drive),
    ]);

    final options = <TransportOption>[];
    final modes = [TransportMode.walk, TransportMode.twoWheeler, TransportMode.drive];

    for (int i = 0; i < modes.length; i++) {
      final result = results[i];
      if (result != null) {
        options.add(result);
      } else {
        // Fallback estimates
        options.add(_fallback(modes[i], straightLineKm));
      }
    }

    return options;
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  double _straightLineKm(LatLng from, LatLng to) {
    const earthRadius = 6371.0;
    final dLat = _toRad(to.latitude - from.latitude);
    final dLng = _toRad(to.longitude - from.longitude);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(from.latitude)) *
            _cos(_toRad(to.latitude)) *
            _sin2(dLng / 2);
    return earthRadius * 2 * _atan2(_sqrt(a), _sqrt(1 - a));
  }

  TransportOption _fallback(TransportMode mode, double km) {
    final km2 = km * 1.15; // road factor
    return switch (mode) {
      TransportMode.walk => TransportOption(
          mode: mode,
          distanceKm: km2,
          durationMinutes: (km2 / 5 * 60).ceil(),
        ),
      TransportMode.twoWheeler => TransportOption(
          mode: mode,
          distanceKm: km2,
          durationMinutes: (km2 / 25 * 60).ceil(),
        ),
      TransportMode.drive => TransportOption(
          mode: mode,
          distanceKm: km2,
          durationMinutes: (km2 / 30 * 60).ceil(),
        ),
      _ => TransportOption(
          mode: mode,
          distanceKm: km2,
          durationMinutes: (km2 / 15 * 60).ceil(),
        ),
    };
  }

  // Basic trig helpers to avoid dart:math import conflicts
  double _toRad(double deg) => deg * 3.141592653589793 / 180;
  double _sin2(double x) => _sin(x) * _sin(x);
  double _sin(double x) => x - x * x * x / 6 + x * x * x * x * x / 120;
  double _cos(double x) => 1 - x * x / 2 + x * x * x * x / 24;
  double _sqrt(double x) => x <= 0 ? 0 : _sqrtApprox(x);
  double _sqrtApprox(double x) {
    double z = x / 2;
    for (int i = 0; i < 10; i++) {
      z = (z + x / z) / 2;
    }
    return z;
  }
  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0;
  }
  double _atan(double x) {
    return x - x * x * x / 3 + x * x * x * x * x / 5;
  }
}
