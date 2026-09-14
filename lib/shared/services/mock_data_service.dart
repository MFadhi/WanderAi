import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';
import '../models/recommendation_model.dart';
import '../models/transport_model.dart';

/// Provides complete, realistic mock data for Kannur, Kerala.
/// Used when API keys are not configured (AppConfig.useMockData == true).
class MockDataService {
  MockDataService._();

  // ─────────────────────────────────────────────
  // Mock Places (Kannur, Kerala)
  // ─────────────────────────────────────────────

  static final List<Place> places = [
    Place(
      id: 'mock_01',
      name: 'Malabar Palace Restaurant',
      location: const LatLng(11.8693, 75.3620),
      formattedAddress: 'Fort Road, Kannur, Kerala 670001',
      rating: 4.6,
      userRatingsTotal: 2847,
      primaryType: 'restaurant',
      openNow: true,
      priceLevel: PriceLevel.moderate,
      photoNames: [],
      editorialSummary:
          'An iconic restaurant renowned for authentic Malabar cuisine, '
          'especially their legendary biryani and coastal seafood.',
      reviews: [
        const PlaceReview(
          authorName: 'Arjun Nair',
          rating: 5.0,
          text:
              'Best Malabar biryani I\'ve had. The flavours are incredible — '
              'perfectly spiced and the portions are generous.',
          relativeTime: '2 weeks ago',
        ),
        const PlaceReview(
          authorName: 'Priya Menon',
          rating: 4.0,
          text:
              'Great food and friendly service. Gets a bit crowded during '
              'dinner but worth the wait. Try the fish curry!',
          relativeTime: '1 month ago',
        ),
        const PlaceReview(
          authorName: 'Rahul K',
          rating: 5.0,
          text:
              'Authentic Malabar cuisine. The mutton biryani is exceptional. '
              'Parking can be tricky near the fort.',
          relativeTime: '3 weeks ago',
        ),
      ],
      distanceKm: 2.1,
    ),
    Place(
      id: 'mock_02',
      name: 'St. Angelo Fort (Kannur Fort)',
      location: const LatLng(11.8745, 75.3650),
      formattedAddress: 'Fort Road, Kannur, Kerala 670001',
      rating: 4.4,
      userRatingsTotal: 5621,
      primaryType: 'tourist_attraction',
      openNow: true,
      priceLevel: PriceLevel.inexpensive,
      photoNames: [],
      editorialSummary:
          'A 16th-century Portuguese fort with panoramic Arabian Sea views. '
          'One of the best-preserved forts in Kerala.',
      reviews: [
        const PlaceReview(
          authorName: 'Deepa S',
          rating: 5.0,
          text:
              'Breathtaking sunset views over the Arabian Sea. '
              'The fort is well-maintained and the history is fascinating.',
          relativeTime: '1 week ago',
        ),
        const PlaceReview(
          authorName: 'Mohammed Rafi',
          rating: 4.0,
          text:
              'Beautiful historic fort. Best visited in the evening for the '
              'golden hour photography. Sunset is magical here.',
          relativeTime: '2 months ago',
        ),
      ],
      distanceKm: 1.4,
    ),
    Place(
      id: 'mock_03',
      name: 'Muzhappilangad Drive-In Beach',
      location: const LatLng(11.9260, 75.3480),
      formattedAddress: 'Muzhappilangad, Kannur, Kerala 670604',
      rating: 4.5,
      userRatingsTotal: 8932,
      primaryType: 'natural_feature',
      openNow: true,
      priceLevel: PriceLevel.free,
      photoNames: [],
      editorialSummary:
          'Asia\'s longest drive-in beach stretching 4 km. '
          'The only beach in India where you can drive along the shoreline.',
      reviews: [
        const PlaceReview(
          authorName: 'Sneha R',
          rating: 5.0,
          text:
              'Absolutely stunning! You can actually drive on the beach. '
              'The waves are beautiful and the sunset here is unforgettable.',
          relativeTime: '5 days ago',
        ),
        const PlaceReview(
          authorName: 'Anil Kumar',
          rating: 4.0,
          text:
              'Great experience driving on the beach. Goes very busy on '
              'weekends. Best to visit on a weekday morning.',
          relativeTime: '3 weeks ago',
        ),
      ],
      distanceKm: 4.8,
    ),
    Place(
      id: 'mock_04',
      name: 'Payyambalam Beach Garden',
      location: const LatLng(11.8791, 75.3580),
      formattedAddress: 'Payyambalam, Kannur, Kerala 670001',
      rating: 4.3,
      userRatingsTotal: 3210,
      primaryType: 'park',
      openNow: true,
      priceLevel: PriceLevel.free,
      photoNames: [],
      editorialSummary:
          'A scenic beach garden with a famous sculpture installation '
          'and lovely evening walks along the coast.',
      reviews: [
        const PlaceReview(
          authorName: 'Lakshmi P',
          rating: 4.0,
          text:
              'Peaceful evening spot. The statue of mother and child is iconic. '
              'Great place for a relaxing walk after dinner.',
          relativeTime: '2 weeks ago',
        ),
      ],
      distanceKm: 1.2,
    ),
    Place(
      id: 'mock_05',
      name: 'Marina Café & Bakery',
      location: const LatLng(11.8680, 75.3590),
      formattedAddress: 'SM Street, Kannur, Kerala 670001',
      rating: 4.5,
      userRatingsTotal: 1423,
      primaryType: 'cafe',
      openNow: true,
      priceLevel: PriceLevel.inexpensive,
      photoNames: [],
      editorialSummary:
          'A charming café known for freshly baked goods, '
          'South Indian filter coffee, and a cosy ambiance.',
      reviews: [
        const PlaceReview(
          authorName: 'Fathima A',
          rating: 5.0,
          text:
              'The filter coffee here is the best in Kannur! '
              'Fresh bakery items every morning. Lovely cosy vibe.',
          relativeTime: '1 week ago',
        ),
      ],
      distanceKm: 0.8,
    ),
    Place(
      id: 'mock_06',
      name: 'Arakkal Museum',
      location: const LatLng(11.8720, 75.3640),
      formattedAddress: 'Arakkal Road, Kannur, Kerala 670001',
      rating: 4.2,
      userRatingsTotal: 987,
      primaryType: 'museum',
      openNow: true,
      priceLevel: PriceLevel.inexpensive,
      photoNames: [],
      editorialSummary:
          'The only Muslim royal family museum in Kerala, preserving '
          'the heritage of the Arakkal dynasty.',
      reviews: [
        const PlaceReview(
          authorName: 'Vivek M',
          rating: 4.0,
          text:
              'Fascinating museum with unique Kerala history. '
              'Not many tourists visit so it\'s peaceful. Great for history lovers.',
          relativeTime: '1 month ago',
        ),
      ],
      distanceKm: 1.8,
    ),
    Place(
      id: 'mock_07',
      name: 'Parassinikadavu Snake Park',
      location: const LatLng(12.0012, 75.2897),
      formattedAddress: 'Parassinikadavu, Kannur, Kerala 670563',
      rating: 4.3,
      userRatingsTotal: 4567,
      primaryType: 'tourist_attraction',
      openNow: true,
      priceLevel: PriceLevel.inexpensive,
      photoNames: [],
      editorialSummary:
          'One of Kerala\'s finest snake parks and a famous '
          'Muthappan Temple, perfect for nature and culture enthusiasts.',
      reviews: [
        const PlaceReview(
          authorName: 'Ramesh G',
          rating: 4.0,
          text:
              'Excellent snake park. Saw Cobras and King Cobras up close. '
              'The temple nearby is also worth visiting.',
          relativeTime: '3 weeks ago',
        ),
      ],
      distanceKm: 14.3,
    ),
    Place(
      id: 'mock_08',
      name: 'Coastal Kitchen – Seafood',
      location: const LatLng(11.8670, 75.3610),
      formattedAddress: 'Beach Road, Kannur, Kerala 670001',
      rating: 4.4,
      userRatingsTotal: 1876,
      primaryType: 'restaurant',
      openNow: true,
      priceLevel: PriceLevel.moderate,
      photoNames: [],
      editorialSummary:
          'A beachfront seafood restaurant specialising in fresh Malabar-style '
          'fish curry, prawn masala, and karimeen dishes.',
      reviews: [
        const PlaceReview(
          authorName: 'Suresh P',
          rating: 5.0,
          text:
              'The Karimeen fry is out of this world! '
              'Very fresh fish, clearly caught same day. Amazing views of the sea.',
          relativeTime: '4 days ago',
        ),
      ],
      distanceKm: 1.6,
    ),
  ];

  // ─────────────────────────────────────────────
  // Transport Options
  // ─────────────────────────────────────────────

  static List<TransportOption> mockTransportOptions(double distanceKm) {
    final walkMin = (distanceKm / 5 * 60).round();
    final bikeMin = (distanceKm / 12 * 60).round();
    final twoWheelerMin = (distanceKm / 25 * 60).round();
    final carMin = (distanceKm / 30 * 60).round();

    return [
      if (distanceKm <= 3)
        TransportOption(
          mode: TransportMode.walk,
          distanceKm: distanceKm,
          durationMinutes: walkMin,
          isRecommended: distanceKm <= 0.8,
        ),
      if (distanceKm <= 5)
        TransportOption(
          mode: TransportMode.bicycle,
          distanceKm: distanceKm * 1.05,
          durationMinutes: bikeMin,
        ),
      TransportOption(
        mode: TransportMode.twoWheeler,
        distanceKm: distanceKm * 1.1,
        durationMinutes: twoWheelerMin,
        isRecommended: distanceKm > 0.8 && distanceKm <= 10,
        reason:
            'Fastest option for this distance with easier parking than a car.',
      ),
      TransportOption(
        mode: TransportMode.drive,
        distanceKm: distanceKm * 1.1,
        durationMinutes: carMin,
        isRecommended: distanceKm > 10,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // Mock Top Recommendation
  // ─────────────────────────────────────────────

  static Recommendation get topRecommendation {
    final place = places.first;
    return Recommendation(
      place: place,
      matchScore: 92,
      reason:
          'Based on your location, budget of ₹500, interest in local food, '
          'and strong review sentiment — Malabar Palace is the best match right now. '
          'It\'s highly rated, close to you, and visitors consistently praise the food quality.',
      recommendedTransport: 'TWO_WHEELER',
      estimatedBudget: '₹300–₹500',
      tryThis: 'Malabar Biryani',
      bestTime: '7:00 PM',
      awarenessItems: [
        'May be crowded during dinner (7–9 PM)',
        'Parking near Fort Road can be limited',
        'Arrive early for a window seat',
      ],
      reviewInsights: const ReviewInsights(
        positive: [
          'Authentic Malabar flavours',
          'Generous portions',
          'Friendly and attentive service',
          'Frequently praised for food quality',
        ],
        negative: [
          'Can get very crowded during dinner hours',
          'Waiting time may increase after 7:30 PM',
          'Parking near the fort is limited',
        ],
      ),
      transportOptions: mockTransportOptions(place.distanceKm ?? 2.1),
      goodFor: ['Food lovers', 'Families', 'Couples', 'Solo travelers'],
    );
  }

  // ─────────────────────────────────────────────
  // Mock Chat Responses
  // ─────────────────────────────────────────────

  static const Map<String, String> mockChatResponses = {
    'food': '''**🍛 Best Food Spots Near You**

Based on your location in Kannur and your budget of ₹500, here are my top picks:

**1. Malabar Palace Restaurant** ⭐ 4.6
📍 2.1 km away · 🛵 8 min
*Try the Malabar Biryani — it's what they're famous for.*
💰 ₹300–₹500 per person

**2. Coastal Kitchen** ⭐ 4.4
📍 1.6 km away · 🛵 6 min
*Fresh-catch seafood. Try the Karimeen fry.*
💰 ₹250–₹450 per person

🛡️ **Be aware**: Both restaurants get busy after 7 PM. Consider visiting before 7 or after 8:30 for shorter wait times.''',

    'time': '''**⏱️ 2-Hour Plan for You**

Here's the perfect 2-hour evening itinerary:

**5:30 PM** · 🏛️ St. Angelo Fort
*Explore the 16th-century fort with stunning sea views.*
↓ 8 min by two-wheeler

**6:30 PM** · 🌅 Payyambalam Beach
*Catch the golden hour at this peaceful beach garden.*
↓ 5 min

**7:15 PM** · 🍛 Malabar Palace Restaurant
*End with an authentic Malabar biryani dinner.*

💰 Total estimated cost: ₹350–₹500
🛵 Best transport: Two-wheeler throughout''',

    'photo': '''**📸 Best Photography Spots in Kannur**

**1. St. Angelo Fort** — Sunset & seascape
*Golden hour views over the Arabian Sea. Best 5:30–6:30 PM*

**2. Muzhappilangad Beach** — Drive-in beach
*Long stretches of shoreline. Best in the morning (7–9 AM)*

**3. Payyambalam Garden** — Cultural + coastal
*The Mother & Child sculpture is iconic for photography*

🛡️ Tips:
• Visit forts during the golden hour (1 hour before sunset)
• Beach photography is best on weekday mornings when less crowded''',

    'default': '''I'm WanderAI, your personal tour guide for Kannur! 🗺️

I can help you with:
• **Where to eat** – personalized restaurant picks
• **What to see** – curated attraction recommendations  
• **How to get there** – best transport advice
• **Trip planning** – complete itineraries
• **Local tips** – what to try, when to go, what to avoid

What would you like to explore? Ask me anything!''',
  };

  static String getMockChatResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('eat') || q.contains('food') || q.contains('restaurant') ||
        q.contains('biryani') || q.contains('hungry')) {
      return mockChatResponses['food']!;
    }
    if (q.contains('hour') || q.contains('time') || q.contains('itinerary') ||
        q.contains('plan')) {
      return mockChatResponses['time']!;
    }
    if (q.contains('photo') || q.contains('picture') || q.contains('shoot') ||
        q.contains('camera') || q.contains('sunset')) {
      return mockChatResponses['photo']!;
    }
    return mockChatResponses['default']!;
  }
}
