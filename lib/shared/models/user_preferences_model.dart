import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/constants.dart';

// ─────────────────────────────────────────────
// User Interests
// ─────────────────────────────────────────────

const List<String> kAllInterests = [
  'Food',
  'Cafés',
  'Nature',
  'History',
  'Photography',
  'Shopping',
  'Adventure',
  'Culture',
];

// ─────────────────────────────────────────────
// User Preferences
// ─────────────────────────────────────────────

class UserPreferences {
  final List<String> interests;
  final double maxBudget; // INR
  final String preferredTransport; // TransportMode.apiValue
  final double availableHours;
  final List<String> dietaryPreferences;
  final bool vegetarian;
  final String travelStyle; // Relaxed / Balanced / Fast-paced

  const UserPreferences({
    required this.interests,
    required this.maxBudget,
    required this.preferredTransport,
    required this.availableHours,
    this.dietaryPreferences = const [],
    this.vegetarian = false,
    this.travelStyle = 'Balanced',
  });

  /// Sensible defaults shown on first launch
  static UserPreferences defaults() => const UserPreferences(
        interests: ['Attractions', 'Nature', 'Food', 'History'],
        maxBudget: 1000,
        preferredTransport: 'TWO_WHEELER',
        availableHours: 3.0,
        dietaryPreferences: [],
        vegetarian: false,
        travelStyle: 'Balanced',
      );

  UserPreferences copyWith({
    List<String>? interests,
    double? maxBudget,
    String? preferredTransport,
    double? availableHours,
    List<String>? dietaryPreferences,
    bool? vegetarian,
    String? travelStyle,
  }) =>
      UserPreferences(
        interests: interests ?? this.interests,
        maxBudget: maxBudget ?? this.maxBudget,
        preferredTransport: preferredTransport ?? this.preferredTransport,
        availableHours: availableHours ?? this.availableHours,
        dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
        vegetarian: vegetarian ?? this.vegetarian,
        travelStyle: travelStyle ?? this.travelStyle,
      );

  Map<String, dynamic> toJson() => {
        'interests': interests,
        'maxBudget': maxBudget,
        'preferredTransport': preferredTransport,
        'availableHours': availableHours,
        'dietaryPreferences': dietaryPreferences,
        'vegetarian': vegetarian,
        'travelStyle': travelStyle,
      };

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        interests: (json['interests'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['Food', 'Nature'],
        maxBudget: (json['maxBudget'] as num?)?.toDouble() ?? 500,
        preferredTransport:
            json['preferredTransport'] as String? ?? 'TWO_WHEELER',
        availableHours: (json['availableHours'] as num?)?.toDouble() ?? 3.0,
        dietaryPreferences:
            (json['dietaryPreferences'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
        vegetarian: json['vegetarian'] as bool? ?? false,
        travelStyle: json['travelStyle'] as String? ?? 'Balanced',
      );

  /// Persist to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyPreferences, jsonEncode(toJson()));
  }

  /// Load from SharedPreferences
  static Future<UserPreferences> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyPreferences);
      if (raw == null) return defaults();
      return UserPreferences.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return defaults();
    }
  }

  /// Gemini prompt representation
  String toPromptString() {
    return '''
User Preferences:
- Interests: ${interests.join(', ')}
- Budget: ₹${maxBudget.toStringAsFixed(0)}
- Preferred transport: $preferredTransport
- Available time: ${availableHours}h
- Travel style: $travelStyle
- Vegetarian: $vegetarian
${dietaryPreferences.isNotEmpty ? '- Dietary: ${dietaryPreferences.join(', ')}' : ''}
''';
  }
}
