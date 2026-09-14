import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';
import '../models/place_model.dart';

/// Google Places API (New) service.
/// Uses POST endpoints with mandatory X-Goog-FieldMask header.
class PlacesService {
  PlacesService() : _dio = DioClient.places;

  final Dio _dio;

  // ─────────────────────────────────────────────
  // Field masks for efficient API calls
  // ─────────────────────────────────────────────

  static const String _listFieldMask =
      'places.id,'
      'places.displayName,'
      'places.formattedAddress,'
      'places.location,'
      'places.rating,'
      'places.userRatingCount,'
      'places.priceLevel,'
      'places.currentOpeningHours,'
      'places.primaryType,'
      'places.photos,'
      'places.editorialSummary';

  static const String _detailFieldMask =
      'id,'
      'displayName,'
      'formattedAddress,'
      'location,'
      'rating,'
      'userRatingCount,'
      'priceLevel,'
      'currentOpeningHours,'
      'primaryType,'
      'photos,'
      'editorialSummary,'
      'reviews,'
      'websiteUri,'
      'internationalPhoneNumber';

  // ─────────────────────────────────────────────
  // Nearby Search
  // ─────────────────────────────────────────────

  Future<List<Place>> nearbySearch({
    required LatLng location,
    required String placeType,
    double radiusMeters = 5000,
    int maxResults = 20,
  }) async {
    try {
      final response = await _dio.post(
        '/places:searchNearby',
        queryParameters: {'key': AppConfig.googleMapsApiKey},
        options: Options(headers: {'X-Goog-FieldMask': _listFieldMask}),
        data: {
          'locationRestriction': {
            'circle': {
              'center': {
                'latitude': location.latitude,
                'longitude': location.longitude,
              },
              'radius': radiusMeters,
            },
          },
          'includedTypes': [placeType],
          'maxResultCount': maxResults,
          'rankPreference': 'POPULARITY',
        },
      );

      final placesJson =
          (response.data['places'] as List<dynamic>?) ?? [];
      return placesJson
          .map((p) => Place.fromPlacesApiJson(p as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error']?['message'] as String? ??
            'Failed to fetch nearby places',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException(message: 'Network error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Text Search
  // ─────────────────────────────────────────────

  Future<List<Place>> textSearch({
    required String query,
    LatLng? location,
    double? radiusMeters,
    int maxResults = 20,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'textQuery': query,
        'maxResultCount': maxResults,
        'rankPreference': 'RELEVANCE',
      };

      if (location != null && radiusMeters != null) {
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': location.latitude,
              'longitude': location.longitude,
            },
            'radius': radiusMeters,
          },
        };
      }

      final response = await _dio.post(
        '/places:searchText',
        queryParameters: {'key': AppConfig.googleMapsApiKey},
        options: Options(headers: {'X-Goog-FieldMask': _listFieldMask}),
        data: body,
      );

      final placesJson =
          (response.data['places'] as List<dynamic>?) ?? [];
      return placesJson
          .map((p) => Place.fromPlacesApiJson(p as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error']?['message'] as String? ??
            'Text search failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException(message: 'Network error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Place Details
  // ─────────────────────────────────────────────

  Future<Place> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '/places/$placeId',
        queryParameters: {'key': AppConfig.googleMapsApiKey},
        options: Options(headers: {'X-Goog-FieldMask': _detailFieldMask}),
      );

      return Place.fromPlacesApiJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['error']?['message'] as String? ??
            'Failed to get place details',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw NetworkException(message: 'Network error: $e');
    }
  }

  // ─────────────────────────────────────────────
  // Photo URL
  // ─────────────────────────────────────────────

  /// Build a photo URL from a Places API photo resource name.
  /// photoName format: "places/{placeId}/photos/{photoId}"
  String getPhotoUrl(String photoName, {int maxWidth = 800}) {
    return '${AppConfig.placesBaseUrl}/$photoName/media'
        '?key=${AppConfig.googleMapsApiKey}'
        '&maxWidthPx=$maxWidth';
  }
}
