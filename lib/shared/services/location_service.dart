import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/errors/exceptions.dart';

/// Platform-aware location settings that disable NMEA on Android
/// to prevent NmeaClient crash on API 37+ emulators.
LocationSettings _platformLocationSettings({
  LocationAccuracy accuracy = LocationAccuracy.high,
  int distanceFilter = 0,
}) {
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      useMSLAltitude: false, // prevents NmeaClient.start() crash
    );
  }
  return LocationSettings(
    accuracy: accuracy,
    distanceFilter: distanceFilter,
  );
}

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

    // 3. Get position (try fresh first, fallback to last known if timeout)
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      throw const LocationException(
        message: 'Could not determine your location. Please ensure GPS is active.',
        reason: LocationFailureReason.timeout,
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

  /// Watches live location stream with immediate first-emit.
  Stream<LatLng> watchLocation() {
    late StreamController<LatLng> controller;

    Future<void> start() async {
      try {
        // 1. Check/request permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          controller.close();
          return;
        }

        // 2. Emit last known position immediately (fast)
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && !controller.isClosed) {
          controller.add(LatLng(lastKnown.latitude, lastKnown.longitude));
        }

        // 3. Emit a fresh current position
        try {
          final fresh = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          if (!controller.isClosed) {
            controller.add(LatLng(fresh.latitude, fresh.longitude));
          }
        } catch (_) {}

        // 4. Forward ongoing stream updates (with NMEA disabled)
        final sub = Geolocator.getPositionStream(
          locationSettings: _platformLocationSettings(
            distanceFilter: 10,
          ),
        ).listen(
          (pos) {
            if (!controller.isClosed) {
              controller.add(LatLng(pos.latitude, pos.longitude));
            }
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
          cancelOnError: false,
        );

        controller.onCancel = () => sub.cancel();
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<LatLng>(
      onListen: start,
    );

    return controller.stream;
  }
}
