import 'place_model.dart';
import 'transport_model.dart';

// ─────────────────────────────────────────────
// Itinerary Stop
// ─────────────────────────────────────────────

class ItineraryStop {
  final String time; // e.g. "4:00 PM"
  final Place place;
  final String activity; // Short description
  final String? aiPick; // AI food/activity recommendation
  final List<String> awarenessItems;

  /// Transport to the NEXT stop (null for last stop)
  final TransportOption? transportToNext;

  const ItineraryStop({
    required this.time,
    required this.place,
    required this.activity,
    this.aiPick,
    this.awarenessItems = const [],
    this.transportToNext,
  });

  factory ItineraryStop.fromJson(
    Map<String, dynamic> json,
    Place place,
  ) {
    return ItineraryStop(
      time: json['time'] as String? ?? '',
      place: place,
      activity: json['activity'] as String? ?? '',
      aiPick: json['ai_pick'] as String?,
      awarenessItems: (json['awareness'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      transportToNext: json['transport_to_next'] != null
          ? TransportOption.fromJson(
              json['transport_to_next'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// Itinerary
// ─────────────────────────────────────────────

class Itinerary {
  final String title; // e.g. "🌅 Your Evening Plan"
  final String subtitle; // e.g. "3 stops · ~4 hours · ₹500–₹1,000"
  final List<ItineraryStop> stops;
  final String totalDuration; // e.g. "4 hours"
  final String totalBudget; // e.g. "₹500–₹1,000"

  const Itinerary({
    required this.title,
    required this.subtitle,
    required this.stops,
    required this.totalDuration,
    required this.totalBudget,
  });

  factory Itinerary.fromGeminiJson(
    Map<String, dynamic> json,
    List<Place> places,
  ) {
    final stopsList = (json['stops'] as List<dynamic>?) ?? [];
    final List<ItineraryStop> stops = [];

    for (int i = 0; i < stopsList.length; i++) {
      final stopJson = stopsList[i] as Map<String, dynamic>;
      final placeId = stopJson['place_id'] as String? ?? '';
      Place? place;
      try {
        place = places.firstWhere((p) => p.id == placeId);
      } catch (_) {
        if (places.isNotEmpty && i < places.length) {
          place = places[i];
        }
      }
      if (place != null) {
        stops.add(ItineraryStop.fromJson(stopJson, place));
      }
    }

    return Itinerary(
      title: json['title'] as String? ?? '✨ Your Personalised Plan',
      subtitle: json['subtitle'] as String? ??
          '${stops.length} stops · ${json['total_duration'] ?? ''}',
      stops: stops,
      totalDuration: json['total_duration'] as String? ?? '',
      totalBudget: json['total_budget'] as String? ?? 'N/A',
    );
  }
}
