import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────
// Price Level
// ─────────────────────────────────────────────

enum PriceLevel {
  free,
  inexpensive,
  moderate,
  expensive,
  veryExpensive;

  static PriceLevel fromString(String? value) {
    return switch (value) {
      'PRICE_LEVEL_FREE' => PriceLevel.free,
      'PRICE_LEVEL_INEXPENSIVE' => PriceLevel.inexpensive,
      'PRICE_LEVEL_MODERATE' => PriceLevel.moderate,
      'PRICE_LEVEL_EXPENSIVE' => PriceLevel.expensive,
      'PRICE_LEVEL_VERY_EXPENSIVE' => PriceLevel.veryExpensive,
      _ => PriceLevel.moderate,
    };
  }

  String get symbol {
    return switch (this) {
      PriceLevel.free => 'Free',
      PriceLevel.inexpensive => '₹',
      PriceLevel.moderate => '₹₹',
      PriceLevel.expensive => '₹₹₹',
      PriceLevel.veryExpensive => '₹₹₹₹',
    };
  }
}

// ─────────────────────────────────────────────
// Place Review
// ─────────────────────────────────────────────

class PlaceReview {
  final String authorName;
  final double rating;
  final String text;
  final String? authorPhotoUrl;
  final String? relativeTime;

  const PlaceReview({
    required this.authorName,
    required this.rating,
    required this.text,
    this.authorPhotoUrl,
    this.relativeTime,
  });

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    return PlaceReview(
      authorName:
          json['authorAttribution']?['displayName'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      text: json['text']?['text'] as String? ?? '',
      authorPhotoUrl:
          json['authorAttribution']?['photoUri'] as String?,
      relativeTime: json['relativePublishTimeDescription'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'authorName': authorName,
        'rating': rating,
        'text': text,
        'authorPhotoUrl': authorPhotoUrl,
        'relativeTime': relativeTime,
      };
}

// ─────────────────────────────────────────────
// Opening Hours
// ─────────────────────────────────────────────

class OpeningHours {
  final bool openNow;
  final List<String> weekdayDescriptions;

  const OpeningHours({
    required this.openNow,
    this.weekdayDescriptions = const [],
  });

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      openNow: json['openNow'] as bool? ?? false,
      weekdayDescriptions: (json['weekdayDescriptions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'openNow': openNow,
        'weekdayDescriptions': weekdayDescriptions,
      };
}

// ─────────────────────────────────────────────
// Place Model
// ─────────────────────────────────────────────

class Place {
  final String id;
  final String name;
  final double? rating;
  final int? userRatingsTotal;
  final LatLng location;
  final String formattedAddress;
  final String? primaryType;
  final bool? openNow;
  final PriceLevel? priceLevel;

  /// Photo resource names from Places API (New): "places/{placeId}/photos/{photoId}"
  final List<String> photoNames;

  final String? editorialSummary;
  final List<PlaceReview> reviews;
  final String? website;
  final String? phoneNumber;
  final OpeningHours? openingHours;

  // Set externally after computing distance from user location
  double? distanceKm;

  Place({
    required this.id,
    required this.name,
    required this.location,
    required this.formattedAddress,
    this.rating,
    this.userRatingsTotal,
    this.primaryType,
    this.openNow,
    this.priceLevel,
    this.photoNames = const [],
    this.editorialSummary,
    this.reviews = const [],
    this.website,
    this.phoneNumber,
    this.openingHours,
    this.distanceKm,
  });

  /// Parse from Places API (New) JSON response
  factory Place.fromPlacesApiJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    return Place(
      id: json['id'] as String? ?? '',
      name: json['displayName']?['text'] as String? ?? 'Unknown Place',
      location: LatLng(
        (loc['latitude'] as num?)?.toDouble() ?? 0.0,
        (loc['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      formattedAddress: json['formattedAddress'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingCount'] as int?,
      primaryType: json['primaryType'] as String?,
      openNow:
          json['currentOpeningHours']?['openNow'] as bool?,
      priceLevel: PriceLevel.fromString(json['priceLevel'] as String?),
      photoNames: (json['photos'] as List<dynamic>?)
              ?.map((p) => p['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList() ??
          [],
      editorialSummary: json['editorialSummary']?['text'] as String?,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => PlaceReview.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      website: json['websiteUri'] as String?,
      phoneNumber: json['internationalPhoneNumber'] as String?,
      openingHours: json['currentOpeningHours'] != null
          ? OpeningHours.fromJson(
              json['currentOpeningHours'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Parse from simple stored JSON
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      location: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      formattedAddress: json['formattedAddress'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingsTotal: json['userRatingsTotal'] as int?,
      primaryType: json['primaryType'] as String?,
      openNow: json['openNow'] as bool?,
      priceLevel: PriceLevel.fromString(json['priceLevel'] as String?),
      photoNames: (json['photoNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      editorialSummary: json['editorialSummary'] as String?,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => PlaceReview.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      website: json['website'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': location.latitude,
        'lng': location.longitude,
        'formattedAddress': formattedAddress,
        'rating': rating,
        'userRatingsTotal': userRatingsTotal,
        'primaryType': primaryType,
        'openNow': openNow,
        'priceLevel': priceLevel?.name,
        'photoNames': photoNames,
        'editorialSummary': editorialSummary,
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'website': website,
        'phoneNumber': phoneNumber,
        'distanceKm': distanceKm,
      };

  Place copyWith({double? distanceKm}) => Place(
        id: id,
        name: name,
        location: location,
        formattedAddress: formattedAddress,
        rating: rating,
        userRatingsTotal: userRatingsTotal,
        primaryType: primaryType,
        openNow: openNow,
        priceLevel: priceLevel,
        photoNames: photoNames,
        editorialSummary: editorialSummary,
        reviews: reviews,
        website: website,
        phoneNumber: phoneNumber,
        openingHours: openingHours,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  @override
  String toString() => 'Place($id, $name, rating=$rating)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Place && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
