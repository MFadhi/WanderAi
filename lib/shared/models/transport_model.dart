// ─────────────────────────────────────────────
// Transport Mode
// ─────────────────────────────────────────────

enum TransportMode {
  walk,
  bicycle,
  twoWheeler,
  drive,
  transit;

  /// Maps to Google Routes API travelMode field
  String get apiValue {
    return switch (this) {
      TransportMode.walk => 'WALK',
      TransportMode.bicycle => 'BICYCLE',
      TransportMode.twoWheeler => 'TWO_WHEELER',
      TransportMode.drive => 'DRIVE',
      TransportMode.transit => 'TRANSIT',
    };
  }

  /// Human-readable label
  String get label {
    return switch (this) {
      TransportMode.walk => 'Walking',
      TransportMode.bicycle => 'Bicycle',
      TransportMode.twoWheeler => 'Two-wheeler',
      TransportMode.drive => 'Car',
      TransportMode.transit => 'Public transport',
    };
  }

  String get emoji {
    return switch (this) {
      TransportMode.walk => '🚶',
      TransportMode.bicycle => '🚲',
      TransportMode.twoWheeler => '🛵',
      TransportMode.drive => '🚗',
      TransportMode.transit => '🚌',
    };
  }

  static TransportMode fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'WALK' => TransportMode.walk,
      'BICYCLE' => TransportMode.bicycle,
      'TWO_WHEELER' => TransportMode.twoWheeler,
      'DRIVE' => TransportMode.drive,
      'TRANSIT' => TransportMode.transit,
      _ => TransportMode.twoWheeler,
    };
  }
}

// ─────────────────────────────────────────────
// Transport Option
// ─────────────────────────────────────────────

class TransportOption {
  final TransportMode mode;
  final double distanceKm;
  final int durationMinutes;
  final bool isRecommended;

  /// Gemini-generated reason for recommendation
  final String? reason;

  const TransportOption({
    required this.mode,
    required this.distanceKm,
    required this.durationMinutes,
    this.isRecommended = false,
    this.reason,
  });

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      mode: TransportMode.fromString(json['mode'] as String?),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      isRecommended: json['isRecommended'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.apiValue,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'isRecommended': isRecommended,
        'reason': reason,
      };

  TransportOption copyWith({bool? isRecommended, String? reason}) =>
      TransportOption(
        mode: mode,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        isRecommended: isRecommended ?? this.isRecommended,
        reason: reason ?? this.reason,
      );
}
