import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/chat_message_model.dart';
import '../models/place_model.dart';
import '../models/recommendation_model.dart';
import '../models/itinerary_model.dart';
import '../models/transport_model.dart';
import '../models/user_preferences_model.dart';
import 'mock_data_service.dart';

class GeminiService {
  GeminiService() : _dio = DioClient.gemini;

  final Dio _dio;

  String get _endpoint =>
      '/models/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}';

  /// Check if we should run in mock mode
  bool get _shouldMock => AppConfig.useMockGemini;

  // ─────────────────────────────────────────────
  // Raw Gemini API Request Builder
  // ─────────────────────────────────────────────

  Future<String> _callGemini({
    required String prompt,
    String? message,
    bool forceJson = false,
    List<Map<String, dynamic>>? history,
  }) async {
    if (_shouldMock) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      throw const ServerException(message: 'Running in Mock Mode');
    }

    try {
      final List<Map<String, dynamic>> contents = [];

      if (message != null) {
        // System instructions context in chat mode
        contents.add({
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        });
        contents.add({
          'role': 'model',
          'parts': [
            {'text': "Understood. I will act as WanderAI and personalize my guide responses based on your location and preferences."}
          ]
        });

        // Add history
        if (history != null) {
          contents.addAll(history);
        }

        // Add user message
        contents.add({
          'role': 'user',
          'parts': [
            {'text': message}
          ]
        });
      } else {
        // One-off direct prompt
        contents.add({
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        });
      }

      final Map<String, dynamic> body = {
        'contents': contents,
      };

      if (forceJson) {
        body['generationConfig'] = {
          'responseMimeType': 'application/json',
        };
      }

      final response = await _dio.post(
        _endpoint,
        data: body,
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const ServerException(message: 'No response candidates returned by Gemini');
      }

      final text = candidates.first['content']?['parts']?.first['text'] as String?;
      if (text == null) {
        throw const ServerException(message: 'Empty response text from Gemini');
      }

      return text;
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error']?['message'] as String? ??
            'Gemini API request failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException(message: 'Gemini network failure: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Core Feature 1: Rank Recommendation
  // ─────────────────────────────────────────────

  Future<Recommendation> rankRecommendation({
    required Place place,
    required UserPreferences preferences,
    required List<TransportOption> transportOptions,
  }) async {
    final prompt = '''
You are WanderAI, an advanced AI travel assistant. Rank this place for the user.
Analyze these inputs and return a JSON object explaining why and how this place matches the user's specific context.

Place Details:
- Name: ${place.name}
- Category: ${place.primaryType}
- Rating: ${place.rating} (${place.userRatingsTotal} reviews)
- Editorial Summary: ${place.editorialSummary ?? "N/A"}
- Address: ${place.formattedAddress}
- Price Level: ${place.priceLevel?.symbol ?? "Moderate"}
- Google Reviews: ${place.reviews.map((r) => r.text).join('\n---\n')}

User Preferences:
${preferences.toPromptString()}

Computed Transportation Options to Destination:
${transportOptions.map((o) => '- ${o.mode.label}: ${o.distanceKm.toStringAsFixed(1)} km, ${o.durationMinutes} min').join('\n')}

INSTRUCTIONS:
1. Compute an AI Match Score (0 to 100) representing how well this matches the user. Focus on budget, interests, time constraints, reviews, and accessibility.
2. Recommend the best transport mode among the computed options (must be one of: WALK, BICYCLE, TWO_WHEELER, DRIVE, TRANSIT).
3. Extract positive and negative patterns directly from the reviews (do NOT make things up).
4. Identify a specific food or activity recommendation ("try_this") if applicable.
5. Identify practical warnings / awareness items (crowds, parking, safety, infrastructure, weather). Ensure warning language is factual, non-alarmist and cautious (e.g. "pedestrian infrastructure may be limited", instead of "danger").

Return ONLY this JSON format:
{
  "match_score": 90,
  "reason": "detailed explanation of why this fits the user's request, referencing reviews or distance",
  "recommended_transport": "TWO_WHEELER",
  "estimated_budget": "₹300–₹500",
  "try_this": "Malabar Biryani",
  "best_time": "6:30 PM",
  "awareness": [
    "Expect larger crowds between 6 PM and 8 PM",
    "Parking may be limited near Fort Road"
  ],
  "review_insights": {
    "positive": [
      "Authentic local food",
      "Attentive service"
    ],
    "negative": [
      "Long waiting times during peak dinner hours"
    ]
  },
  "good_for": [
    "Food lovers",
    "Solo travelers"
  ]
}
''';

    try {
      final jsonText = await _callGemini(prompt: prompt, forceJson: true);
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      return Recommendation.fromGeminiJson(decoded, place, transportOptions);
    } catch (_) {
      // Fallback: search mock data matching the place name or return defaults
      final mockPlace = MockDataService.places.firstWhere(
        (p) => p.name.toLowerCase().contains(place.name.toLowerCase()) || p.id == place.id,
        orElse: () => MockDataService.places.first,
      );

      // Construct a mock Recommendation based on the place
      final baseMock = MockDataService.topRecommendation;
      return Recommendation(
        place: place.copyWith(distanceKm: place.distanceKm ?? mockPlace.distanceKm),
        matchScore: baseMock.matchScore,
        reason: 'This is a mock recommendation curated for ${place.name}. '
            'It fits your interests in ${preferences.interests.join(", ")} and fits your ₹${preferences.maxBudget} budget.',
        recommendedTransport: preferences.preferredTransport,
        estimatedBudget: '₹200–₹400',
        tryThis: place.primaryType?.contains('restaurant') == true || place.primaryType?.contains('cafe') == true
            ? 'Specialty of the house'
            : 'Explore the main features',
        bestTime: '5:30 PM',
        awarenessItems: [
          'Expect moderate traffic during transit hours.',
          'Bring water and sunscreen for outdoor exploration.',
        ],
        reviewInsights: ReviewInsights(
          positive: place.reviews.take(2).map((r) => r.text.split(' ').take(4).join(' ')).toList(),
          negative: const ['Can get busy on weekends.'],
        ),
        transportOptions: transportOptions,
        goodFor: preferences.interests,
      );
    }
  }

  // ─────────────────────────────────────────────
  // Core Feature 2: Review Insights (Extractor)
  // ─────────────────────────────────────────────

  Future<ReviewInsights> summarizeReviews(Place place) async {
    final prompt = '''
Analyze the following Google Maps reviews for the location: ${place.name}.
Identify and extract key positive visitor patterns and negative visitor warnings.
Only base your analysis on the actual review text provided.

Reviews:
${place.reviews.map((r) => r.text).join('\n---\n')}

Return ONLY this JSON format:
{
  "positive": [
    "Friendly service",
    "Beautiful sea views"
  ],
  "negative": [
    "Parking is limited",
    "Long waiting queues during dinner"
  ]
}
''';

    try {
      final jsonText = await _callGemini(prompt: prompt, forceJson: true);
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      return ReviewInsights.fromJson(decoded);
    } catch (_) {
      // Mock fallback
      final mock = MockDataService.places.firstWhere(
        (p) => p.id == place.id,
        orElse: () => MockDataService.places.first,
      );
      if (mock.reviews.isNotEmpty) {
        return ReviewInsights(
          positive: const ['Authentic local food', 'Generous portion sizes', 'Attentive staff'],
          negative: const ['Waiting time can increase in peak hours', 'Limited parking spots'],
        );
      }
      return ReviewInsights.empty();
    }
  }

  // ─────────────────────────────────────────────
  // Core Feature 3: Try This Food Recommendation
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> generateFoodPick(Place place) async {
    final prompt = '''
Analyze the restaurant/place reviews for: ${place.name}.
Recommend a specific main dish, dessert, or drink to try, based on mention frequency or review highlights.
Provide estimated budgets per person in Indian Rupees (INR).

Reviews:
${place.reviews.map((r) => r.text).join('\n---\n')}

Return ONLY this JSON format:
{
  "dish": "Chicken Biryani",
  "reason": "Reviews frequently highlight the tender chicken and aromatic rice, making it the most ordered item.",
  "drink": "South Indian Filter Coffee",
  "dessert": "Signature Fruit Custard",
  "budget": "₹300–₹500 per person"
}
''';

    try {
      final jsonText = await _callGemini(prompt: prompt, forceJson: true);
      return jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      // Mock fallback
      return {
        'dish': 'Malabar Biryani',
        'reason': 'Aromatic rice with tender spiced mutton, frequently highlighted as the best in town by visitors.',
        'drink': 'Fresh Lime Mint Cooler',
        'dessert': 'Unnakkaya (Sweet Banana Snack)',
        'budget': '₹250–₹400 per person (estimated)'
      };
    }
  }

  // ─────────────────────────────────────────────
  // Core Feature 4: Itinerary Generator
  // ─────────────────────────────────────────────

  Future<Itinerary> generateItinerary({
    required List<Place> places,
    required UserPreferences preferences,
    required String timeConstraint, // e.g. "2 hours", "Half Day", "Full Day"
  }) async {
    final prompt = '''
You are WanderAI, an advanced AI travel planner.
Generate a chronological itinerary starting from now, selecting the best options from the candidate places.
Ensure all selections respect the user preferences, budget, travel style, and available time limit.

Available Candidate Places:
${places.map((p) => '- ID: ${p.id}, Name: ${p.name}, Type: ${p.primaryType}, LatLng: ${p.location.latitude},${p.location.longitude}, Rating: ${p.rating}').join('\n')}

User Context & Constraints:
- Available Time Duration: $timeConstraint
${preferences.toPromptString()}

INSTRUCTIONS:
1. Schedule a sequence of stops with specific timestamps (e.g. 4:00 PM, 5:30 PM).
2. For each stop, provide a specific activity and an AI pick (food to order, specific spot to photograph, etc.).
3. Provide realistic transition timings (transport_to_next) between stops containing travel distance and duration estimates.
4. Calculate total duration and estimated budget for the entire trip.

Return ONLY this JSON format:
{
  "title": "Your Custom Evening Plan",
  "subtitle": "3 stops · 4 hours · ₹500–₹1,000",
  "total_duration": "4 hours",
  "total_budget": "₹500–₹1,000",
  "stops": [
    {
      "time": "4:00 PM",
      "place_id": "candidate_place_id",
      "activity": "Explore the historic watchtowers and watch the waves.",
      "ai_pick": "Walk along the bastions for photography.",
      "awareness": [
        "Expect moderate crowds near sunset",
        "Walking route has limited pedestrian paths"
      ],
      "transport_to_next": {
        "mode": "TWO_WHEELER",
        "distanceKm": 1.8,
        "durationMinutes": 6,
        "isRecommended": true,
        "reason": "Avoids local traffic congestion"
      }
    }
  ]
}
''';

    try {
      final jsonText = await _callGemini(prompt: prompt, forceJson: true);
      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      return Itinerary.fromGeminiJson(decoded, places);
    } catch (_) {
      // Mock Itinerary fallback
      return Itinerary.fromGeminiJson({
        'title': '🌅 Your Custom Evening Plan',
        'subtitle': '3 stops · ~3 hours · ₹400–₹700',
        'total_duration': '3 hours',
        'total_budget': '₹400–₹700',
        'stops': [
          {
            'time': '4:30 PM',
            'place_id': 'mock_02', // St. Angelo Fort
            'activity': 'Explore the 16th-century Portuguese fortress and take sea views.',
            'ai_pick': 'Catch the ocean breeze from the sea wall.',
            'awareness': ['Closes by 6:00 PM', 'Wear walking shoes.'],
            'transport_to_next': {
              'mode': 'TWO_WHEELER',
              'distanceKm': 2.1,
              'durationMinutes': 8,
              'isRecommended': true,
              'reason': 'Quickest route through town.'
            }
          },
          {
            'time': '5:30 PM',
            'place_id': 'mock_04', // Payyambalam Beach
            'activity': 'Watch the sunset and enjoy a beachside garden walk.',
            'ai_pick': 'Photograph the Mother & Child sculpture.',
            'awareness': ['Carry an umbrella if skies look dark.', 'Pedestrian routes may be limited.'],
            'transport_to_next': {
              'mode': 'TWO_WHEELER',
              'distanceKm': 1.2,
              'durationMinutes': 5,
              'isRecommended': true,
              'reason': 'Short and scenic ride.'
            }
          },
          {
            'time': '6:30 PM',
            'place_id': 'mock_01', // Malabar Palace Restaurant
            'activity': 'Enjoy dinner showcasing authentic local Malabar delicacies.',
            'ai_pick': 'Try the Malabar Biryani and Fresh Lemon juice.',
            'awareness': ['Gets crowded after 7:15 PM.', 'Parking is limited.'],
          }
        ]
      }, places.isNotEmpty ? places : MockDataService.places);
    }
  }

  // ─────────────────────────────────────────────
  // Core Feature 5: Conversational AI assistant
  // ─────────────────────────────────────────────

  Future<String> getChatResponse({
    required String message,
    required UserPreferences preferences,
    required List<Place> nearbyPlaces,
    required List<ChatMessage> history,
  }) async {
    final historyList = history
        .where((m) => m.id != 'loading')
        .map((m) => m.toGeminiJson())
        .toList();

    final prompt = '''
You are WanderAI, a conversational premium travel assistant.
Answer the user's travel question by reasoning over their context and nearby locations.

User Profile & Preferences:
${preferences.toPromptString()}

Nearby Known Places:
${nearbyPlaces.map((p) => '- Name: ${p.name}, Rating: ${p.rating}, Distance: ${p.distanceKm?.toStringAsFixed(1) ?? "N/A"} km, Type: ${p.primaryType}, Summary: ${p.editorialSummary ?? ""}').join('\n')}

INSTRUCTIONS:
1. Provide highly personalized, structured, and visually clean replies. Use Markdown formatting.
2. Suggest specific dishes, paths, or actions depending on interests (local food, nature, photography, history).
3. Recommend travel modes and state why they fit (e.g. "two-wheeler is best due to narrow roads").
4. Add brief, cautious safety/awareness suggestions (e.g. "Expect weekend crowds" or "Walk with caution as footpaths may be uneven").
5. Do NOT hallucinate. Only make claims backed by real facts. If no nearby places match, explain this and suggest broadening parameters.
6. Keep the reply friendly, professional, and inspiring!
''';

    try {
      return await _callGemini(prompt: prompt, history: historyList, message: message);
    } catch (_) {
      return MockDataService.getMockChatResponse(message);
    }
  }
}
