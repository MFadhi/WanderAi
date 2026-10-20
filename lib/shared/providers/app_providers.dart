import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/utils/constants.dart';
import '../models/chat_message_model.dart';
import '../models/place_model.dart';
import '../models/recommendation_model.dart';
import '../models/itinerary_model.dart';
import '../models/user_preferences_model.dart';
import '../services/gemini_service.dart';
import '../services/location_service.dart';
import '../services/recommendation_engine.dart';

// ─────────────────────────────────────────────
// Service Providers
// ─────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
final recommendationEngineProvider = Provider<RecommendationEngine>((ref) => RecommendationEngine());

// ─────────────────────────────────────────────
// User Preferences Provider
// ─────────────────────────────────────────────

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(UserPreferences.defaults()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await UserPreferences.load();
    state = prefs;
  }

  Future<void> updatePreferences(UserPreferences updated) async {
    state = updated;
    await updated.save();
  }

  Future<void> updateDietary(List<String> dietary, bool veg) async {
    final updated = state.copyWith(dietaryPreferences: dietary, vegetarian: veg);
    state = updated;
    await updated.save();
  }

  Future<void> updateInterests(List<String> interests) async {
    final updated = state.copyWith(interests: interests);
    state = updated;
    await updated.save();
  }

  Future<void> updateBudgetAndTime(double budget, double hours) async {
    final updated = state.copyWith(maxBudget: budget, availableHours: hours);
    state = updated;
    await updated.save();
  }

  Future<void> updatePreferredTransport(String transport) async {
    final updated = state.copyWith(preferredTransport: transport);
    state = updated;
    await updated.save();
  }
}

final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});

// ─────────────────────────────────────────────
// Location Stream Provider
// ─────────────────────────────────────────────

final locationStreamProvider = StreamProvider<LatLng>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.watchLocation();
});

// ─────────────────────────────────────────────
// Current City Name Provider (Reverse Geocoding)
// ─────────────────────────────────────────────

final currentCityNameProvider = FutureProvider<String>((ref) async {
  final locAsync = ref.watch(locationStreamProvider);
  return locAsync.when(
    data: (loc) async {
      if (AppConfig.hasGoogleMapsKey) {
        try {
          final dio = Dio();
          final res = await dio.get(
            'https://maps.googleapis.com/maps/api/geocode/json',
            queryParameters: {
              'latlng': '${loc.latitude},${loc.longitude}',
              'key': AppConfig.googleMapsApiKey,
              'result_type':
                  'locality|sublocality|administrative_area_level_2|administrative_area_level_1',
            },
          );
          if (res.statusCode == 200 &&
              res.data['results'] is List &&
              (res.data['results'] as List).isNotEmpty) {
            final components =
                res.data['results'][0]['address_components'] as List<dynamic>;
            for (var c in components) {
              final types = (c['types'] as List<dynamic>).cast<String>();
              if (types.contains('locality') || types.contains('sublocality')) {
                return c['long_name'] as String;
              }
            }
            for (var c in components) {
              final types = (c['types'] as List<dynamic>).cast<String>();
              if (types.contains('administrative_area_level_2') ||
                  types.contains('administrative_area_level_1')) {
                return c['long_name'] as String;
              }
            }
          }
        } catch (_) {}
      }

      return '${loc.latitude.toStringAsFixed(2)}, ${loc.longitude.toStringAsFixed(2)}';
    },
    loading: () => 'Locating...',
    error: (err, _) => 'Location Unavailable',
  );
});

// ─────────────────────────────────────────────
// Saved Places Provider
// ─────────────────────────────────────────────

class SavedPlacesNotifier extends StateNotifier<List<Place>> {
  SavedPlacesNotifier() : super([]) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(AppConstants.prefKeySavedPlaces);
      if (list != null) {
        state = list.map((item) => Place.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> toggleSave(Place place) async {
    final isSaved = state.any((p) => p.id == place.id);
    List<Place> updatedList;
    if (isSaved) {
      updatedList = state.where((p) => p.id != place.id).toList();
    } else {
      updatedList = [...state, place];
    }
    state = updatedList;

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = updatedList.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(AppConstants.prefKeySavedPlaces, list);
    } catch (_) {}
  }

  bool isSaved(String placeId) {
    return state.any((p) => p.id == placeId);
  }
}

final savedPlacesProvider = StateNotifierProvider<SavedPlacesNotifier, List<Place>>((ref) {
  return SavedPlacesNotifier();
});

// ─────────────────────────────────────────────
// Recommendation Providers
// ─────────────────────────────────────────────

final recommendationListProvider = FutureProvider<List<Recommendation>>((ref) async {
  final engine = ref.watch(recommendationEngineProvider);
  final preferences = ref.watch(userPreferencesProvider);

  // We fetch recommendations based on preferences
  return await engine.getRecommendations(preferences: preferences);
});

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final homeCategoryProvider = StateProvider<String>((ref) => 'All');

final homeRecommendationProvider = FutureProvider<Recommendation?>((ref) async {
  final engine = ref.watch(recommendationEngineProvider);
  final preferences = ref.watch(userPreferencesProvider);
  final category = ref.watch(homeCategoryProvider);

  final list = await engine.getRecommendations(
    preferences: preferences,
    categoryFilter: category == 'All' ? null : category,
  );
  return list.isNotEmpty ? list.first : null;
});

final homeRecommendationListProvider = FutureProvider<List<Recommendation>>((ref) async {
  final engine = ref.watch(recommendationEngineProvider);
  final preferences = ref.watch(userPreferencesProvider);
  final category = ref.watch(homeCategoryProvider);

  final list = await engine.getRecommendations(
    preferences: preferences,
    categoryFilter: category == 'All' ? null : category,
  );
  return list.take(5).toList();
});

final currentRecommendationProvider = Provider<AsyncValue<Recommendation?>>((ref) {
  return ref.watch(homeRecommendationProvider);
});

final exploreCategoryProvider = StateProvider<String>((ref) => 'All');

final exploreRecommendationsProvider = FutureProvider<List<Recommendation>>((ref) async {
  final engine = ref.watch(recommendationEngineProvider);
  final preferences = ref.watch(userPreferencesProvider);
  final category = ref.watch(exploreCategoryProvider);

  return await engine.getRecommendations(
    preferences: preferences,
    categoryFilter: category == 'All' ? null : category,
  );
});

// ─────────────────────────────────────────────
// AI Chat Assistant Provider
// ─────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({
    required this.messages,
    this.isLoading = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._geminiService, this._ref)
      : super(ChatState(messages: [])) {
    // Initial welcome message
    state = ChatState(messages: [
      ChatMessage(
        id: 'welcome',
        role: MessageRole.assistant,
        content: 'Hello! I am WanderAI, your personal travel assistant. 🗺️\n\n'
            'Tell me what you are looking for! For example:\n'
            '• *"Where should I eat nearby?"*\n'
            '• *"I have 2 hours. What should I explore?"*\n'
            '• *"Find a peaceful place for photography."*\n\n'
            'How can I help you discover the area today?',
        timestamp: DateTime.now(),
      )
    ]);
  }

  final GeminiService _geminiService;
  final Ref _ref;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage.user(text);
    final loadingMsg = ChatMessage.loading();

    // Add user message and temporary typing loading state
    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
    );

    try {
      final preferences = _ref.read(userPreferencesProvider);

      // Fetch some nearby places to pass to Gemini context
      List<Place> nearbyPlaces = [];
      try {
        final recommendations = _ref.read(recommendationListProvider).value ?? [];
        nearbyPlaces = recommendations.map((r) => r.place).toList();
      } catch (_) {}

      // Query Gemini
      final responseText = await _geminiService.getChatResponse(
        message: text,
        preferences: preferences,
        nearbyPlaces: nearbyPlaces,
        history: state.messages.where((m) => m.id != 'loading').toList(),
      );

      final aiMsg = ChatMessage.assistant(responseText);

      // Remove loading indicator and add AI response
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != 'loading').toList()..add(aiMsg),
        isLoading: false,
      );
    } catch (e) {
      final errMsg = ChatMessage.assistant(
        'Sorry, I encountered an issue while generating a response. '
        'Please check your internet connection and try again.',
      );
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != 'loading').toList()..add(errMsg),
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = ChatState(messages: [
      ChatMessage(
        id: 'welcome',
        role: MessageRole.assistant,
        content: 'Hello! I am WanderAI, your personal travel assistant. 🗺️\n\n'
            'How can I help you discover the area today?',
        timestamp: DateTime.now(),
      )
    ]);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final gemini = ref.watch(geminiServiceProvider);
  return ChatNotifier(gemini, ref);
});

// ─────────────────────────────────────────────
// Itinerary Provider
// ─────────────────────────────────────────────

class ItineraryState {
  final Itinerary? itinerary;
  final bool isLoading;
  final String? errorMessage;

  ItineraryState({
    this.itinerary,
    this.isLoading = false,
    this.errorMessage,
  });

  ItineraryState copyWith({
    Itinerary? itinerary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ItineraryState(
      itinerary: itinerary ?? this.itinerary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ItineraryNotifier extends StateNotifier<ItineraryState> {
  ItineraryNotifier(this._recommendationEngine, this._ref) : super(ItineraryState());

  final RecommendationEngine _recommendationEngine;
  final Ref _ref;

  Future<void> generateItinerary(String timeConstraint) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final preferences = _ref.read(userPreferencesProvider);
      final itinerary = await _recommendationEngine.getItinerary(
        preferences: preferences,
        timeConstraint: timeConstraint,
      );

      state = state.copyWith(itinerary: itinerary, isLoading: false);
    } catch (e) {
      final String msg = e is LocationException
          ? e.message
          : 'I couldn\'t create a reliable itinerary. Please check your location or network and try again.';
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
    }
  }
}

final itineraryProvider = StateNotifierProvider<ItineraryNotifier, ItineraryState>((ref) {
  final engine = ref.watch(recommendationEngineProvider);
  return ItineraryNotifier(engine, ref);
});
