import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/errors/exceptions.dart';

/// Handles device GPS and distance computation.
class LocationService {
  /// Returns the user's current GPS position.
  /// Throws [LocationException] on failure.
  Future<LatLng> getCurrentLocation() async {
    // 1. Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        message:
            'Location services are disabled. Please enable GPS in your device settings.',
        reason: LocationFailureReason.serviceDisabled,
      );
    }

    // 2. Check & request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          message: 'Location permission was denied.',
          reason: LocationFailureReason.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        message:
            'Location permission is permanently denied. '
            'Please go to Settings → Privacy → Location Services to enable it.',
        reason: LocationFailureReason.permissionPermanentlyDenied,
      );
    }

    // 3. Get position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return LatLng(position.latitude, position.longitude);
    } on TimeoutException {
      throw const LocationException(
        message: 'Location request timed out. Please try again.',
        reason: LocationFailureReason.timeout,
      );
    } catch (e) {
      throw LocationException(
        message: 'Could not determine your location: $e',
        reason: LocationFailureReason.unknown,
      );
    }
  }

  /// Calculates the straight-line distance between two coordinates in km.
  double distanceBetween(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000.0;
  }

  /// Watches live location stream.
  Stream<LatLng> watchLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // update every 50m
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }
}
