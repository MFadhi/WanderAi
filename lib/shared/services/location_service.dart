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

    // 3. Get position (check last known first, then try fresh position)
    final lastKnown = await Geolocator.getLastKnownPosition();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
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

  /// Opens device location settings.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens application permission settings.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Watches live location stream with immediate first-emit.
  Stream<LatLng> watchLocation() {
    late StreamController<LatLng> controller;

    Future<void> start() async {
      try {
        // 1. Check if location services are enabled
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!controller.isClosed) {
            controller.addError(const LocationException(
              message:
                  'Location services are disabled. Please enable GPS in device settings.',
              reason: LocationFailureReason.serviceDisabled,
            ));
          }
          return;
        }

        // 2. Check/request permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          if (!controller.isClosed) {
            controller.addError(const LocationException(
              message:
                  'Location permission was denied. Please allow location access.',
              reason: LocationFailureReason.permissionDenied,
            ));
          }
          return;
        }
        if (permission == LocationPermission.deniedForever) {
          if (!controller.isClosed) {
            controller.addError(const LocationException(
              message:
                  'Location permission is permanently denied. Please enable it in Settings.',
              reason: LocationFailureReason.permissionPermanentlyDenied,
            ));
          }
          return;
        }

        // 3. Emit last known position immediately (fast)
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && !controller.isClosed) {
          controller.add(LatLng(lastKnown.latitude, lastKnown.longitude));
        }

        // 4. Emit a fresh current position
        try {
          final fresh = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8),
          );
          if (!controller.isClosed) {
            controller.add(LatLng(fresh.latitude, fresh.longitude));
          }
        } catch (_) {
          if (lastKnown == null && !controller.isClosed) {
            controller.addError(const LocationException(
              message:
                  'Could not determine your location. Please check your GPS signal.',
              reason: LocationFailureReason.timeout,
            ));
          }
        }

        // 5. Forward ongoing stream updates (with NMEA disabled)
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
            if (!controller.isClosed) {
              controller.addError(LocationException(
                message: 'Error tracking location: $e',
                reason: LocationFailureReason.unknown,
              ));
            }
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
