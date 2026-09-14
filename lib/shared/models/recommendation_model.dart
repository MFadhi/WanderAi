import 'place_model.dart';
import 'transport_model.dart';

// ─────────────────────────────────────────────
// Review Insights
// ─────────────────────────────────────────────

class ReviewInsights {
  /// Positive patterns extracted from reviews (e.g. "Authentic food")
  final List<String> positive;

  /// Negative patterns / caveats (e.g. "Gets crowded during dinner")
  final List<String> negative;

  const ReviewInsights({
    this.positive = const [],
    this.negative = const [],
  });

  factory ReviewInsights.empty() => const ReviewInsights();

  factory ReviewInsights.fromJson(Map<String, dynamic> json) => ReviewInsights(
        positive: (json['positive'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        negative: (json['negative'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'positive': positive,
        'negative': negative,
      };
}

// ─────────────────────────────────────────────
// Recommendation
// ─────────────────────────────────────────────

class Recommendation {
  final Place place;

  /// AI match score 0–100
  final int matchScore;

  /// Gemini-generated explanation of why this was chosen
  final String reason;

  /// Best transport mode string e.g. "TWO_WHEELER"
  final String recommendedTransport;

  /// e.g. "₹300–₹500"
  final String estimatedBudget;

  /// What to order / do: e.g. "Malabar Biryani"
  final String? tryThis;

  /// Best time to visit: e.g. "7:00 PM"
  final String? bestTime;

  /// Practical awareness items: e.g. ["May be crowded after 7 PM"]
  final List<String> awarenessItems;

  final ReviewInsights reviewInsights;

  /// All computed transport options sorted by duration
  final List<TransportOption> transportOptions;

  /// Tags: Photography, Families, Food lovers, etc.
  final List<String> goodFor;

  const Recommendation({
    required this.place,
    required this.matchScore,
    required this.reason,
    required this.recommendedTransport,
    required this.estimatedBudget,
    this.tryThis,
    this.bestTime,
    this.awarenessItems = const [],
    this.reviewInsights = const ReviewInsights(),
    this.transportOptions = const [],
    this.goodFor = const [],
  });

  /// Build a Recommendation from Gemini JSON + pre-fetched Place + transport data
  factory Recommendation.fromGeminiJson(
    Map<String, dynamic> json,
    Place place,
    List<TransportOption> transportOptions,
  ) {
    return Recommendation(
      place: place,
      matchScore: (json['match_score'] as num?)?.toInt() ?? 70,
      reason: json['reason'] as String? ?? 'AI-recommended based on your preferences.',
      recommendedTransport:
          json['recommended_transport'] as String? ?? 'TWO_WHEELER',
      estimatedBudget: json['estimated_budget'] as String? ?? 'N/A',
      tryThis: json['try_this'] as String?,
      bestTime: json['best_time'] as String?,
      awarenessItems: (json['awareness'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reviewInsights: json['review_insights'] != null
          ? ReviewInsights.fromJson(
              json['review_insights'] as Map<String, dynamic>)
          : ReviewInsights.empty(),
      transportOptions: transportOptions,
      goodFor: (json['good_for'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  TransportMode get recommendedMode =>
      TransportMode.fromString(recommendedTransport);

  TransportOption? get recommendedOption => transportOptions
      .where((o) => o.mode == recommendedMode)
      .cast<TransportOption?>()
      .firstOrNull;

  @override
  String toString() =>
      'Recommendation(${place.name}, score=$matchScore, transport=$recommendedTransport)';
}
