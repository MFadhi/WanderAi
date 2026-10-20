import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/app_config.dart';
import '../models/place_model.dart';
import '../models/recommendation_model.dart';
import '../models/itinerary_model.dart';
import '../models/transport_model.dart';
import '../models/user_preferences_model.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'routes_service.dart';
import 'gemini_service.dart';
import 'mock_data_service.dart';

class RecommendationEngine {
  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();
  final RoutesService _routesService = RoutesService();
  final GeminiService _geminiService = GeminiService();

  /// Retrieve ranked recommendations based on location and user preferences.
  Future<List<Recommendation>> getRecommendations({
    required UserPreferences preferences,
    String? categoryFilter,
  }) async {
    // 1. Get current user location (throws LocationException if unavailable)
    final LatLng currentLoc = await _locationService.getCurrentLocation();

    List<Place> candidates = [];

    // 2. Fetch candidate places
    if (AppConfig.useMockPlaces) {
      candidates = List.from(MockDataService.places);
      if (categoryFilter != null && categoryFilter != 'All') {
        final searchType = _mapCategoryToPlaceType(categoryFilter);
        final filtered = candidates.where((p) => p.primaryType == searchType).toList();
        if (filtered.isNotEmpty) candidates = filtered;
      }
    } else {
      try {
        if (categoryFilter == null || categoryFilter == 'All') {
          // Fetch places matching top interests in parallel
          final List<Future<List<Place>>> futures = [];
          for (var interest in preferences.interests.take(3)) {
            futures.add(_placesService.nearbySearch(
              location: currentLoc,
              placeType: _mapCategoryToPlaceType(interest),
              radiusMeters: AppConfig.defaultSearchRadius,
            ));
          }
          final res = await Future.wait(futures);
          candidates = res.expand((x) => x).toList();

          if (candidates.isEmpty) {
            candidates = await _placesService.textSearch(
              query: 'top attractions and sightseeing',
              location: currentLoc,
              radiusMeters: AppConfig.defaultSearchRadius,
            );
          }
        } else {
          final searchType = _mapCategoryToPlaceType(categoryFilter);
          candidates = await _placesService.nearbySearch(
            location: currentLoc,
            placeType: searchType,
            radiusMeters: AppConfig.defaultSearchRadius,
          );

          if (candidates.isEmpty) {
            // Fallback to text search if nearbySearch returns empty
            candidates = await _placesService.textSearch(
              query: categoryFilter,
              location: currentLoc,
              radiusMeters: AppConfig.defaultSearchRadius,
            );
          }
        }
      } catch (_) {
        // Fallback to mock data if live API fails
        candidates = List.from(MockDataService.places);
      }
    }

    // If no places found, return empty list
    if (candidates.isEmpty) {
      return [];
    }

    // 3. Compute distances and filter candidates
    final List<Place> validCandidates = [];
    for (var place in candidates) {
      final distance = _locationService.distanceBetween(currentLoc, place.location);
      place.distanceKm = distance;
      validCandidates.add(place);
    }

    // Sort by distance as a baseline
    validCandidates.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    // Limit candidate count to avoid excessive parallel API calls
    final topCandidates = validCandidates.take(5).toList();

    // 4. Generate recommendations using Gemini reasoning in parallel
    final List<Recommendation> recommendations = [];
    final List<Future<Recommendation>> futures = [];

    for (var place in topCandidates) {
      futures.add(_rankPlace(place, currentLoc, preferences));
    }

    final results = await Future.wait(futures);
    for (var rec in results) {
      recommendations.add(rec);
    }

    // Sort recommendations by match score descending
    recommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommendations;
  }

  /// Generate a custom timeline itinerary for the user.
  Future<Itinerary> getItinerary({
    required UserPreferences preferences,
    required String timeConstraint,
  }) async {
    // 1. Retrieve current location (throws LocationException if unavailable)
    final LatLng currentLoc = await _locationService.getCurrentLocation();

    // 2. Fetch multiple candidates covering interests
    List<Place> candidates = [];
    if (AppConfig.useMockPlaces) {
      candidates = List.from(MockDataService.places);
    } else {
      try {
        final List<Future<List<Place>>> searchFutures = [];
        // Fetch up to 3 interest categories
        for (var interest in preferences.interests.take(3)) {
          searchFutures.add(_placesService.nearbySearch(
            location: currentLoc,
            placeType: _mapCategoryToPlaceType(interest),
            radiusMeters: AppConfig.defaultSearchRadius,
          ));
        }
        final results = await Future.wait(searchFutures);
        candidates = results.expand((x) => x).toList();
      } catch (_) {
        candidates = List.from(MockDataService.places);
      }
    }

    if (candidates.isEmpty) {
      candidates = List.from(MockDataService.places);
    }

    // 3. Score and pick best stops
    final List<Place> validCandidates = [];
    for (var place in candidates) {
      place.distanceKm = _locationService.distanceBetween(currentLoc, place.location);
      validCandidates.add(place);
    }
    validCandidates.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));

    final selectedStops = validCandidates.take(4).toList();

    // 4. Generate structured Itinerary via Gemini
    return _geminiService.generateItinerary(
      places: selectedStops,
      preferences: preferences,
      timeConstraint: timeConstraint,
    );
  }

  // Helpers

  Future<Recommendation> _rankPlace(
    Place place,
    LatLng origin,
    UserPreferences preferences,
  ) async {
    // Compute travel routing options (Walk, Two Wheeler, Drive)
    List<TransportOption> transportOptions;
    if (AppConfig.useMockPlaces) {
      transportOptions = MockDataService.mockTransportOptions(place.distanceKm ?? 2.0);
    } else {
      try {
        transportOptions = await _routesService.computeAllRoutes(
          origin: origin,
          destination: place.location,
        );
      } catch (_) {
        transportOptions = MockDataService.mockTransportOptions(place.distanceKm ?? 2.0);
      }
    }

    // Call Gemini to rank and analyze
    return _geminiService.rankRecommendation(
      place: place,
      preferences: preferences,
      transportOptions: transportOptions,
    );
  }

  String _mapCategoryToPlaceType(String category) {
    return switch (category.toLowerCase()) {
      'all' => 'tourist_attraction',
      'attractions' => 'tourist_attraction',
      'food' => 'restaurant',
      'cafés' => 'cafe',
      'nature' => 'park',
      'history' => 'tourist_attraction',
      'photography' => 'scenic_lookout',
      'shopping' => 'shopping_mall',
      'adventure' => 'tourist_attraction',
      'culture' => 'museum',
      _ => 'tourist_attraction',
    };
  }
}
