import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/errors/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/constants.dart';
import '../../shared/models/place_model.dart';
import '../../shared/providers/app_providers.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  GoogleMapController? _mapController;
  Place? _selectedPlace;
  bool _useMockMapFallback = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationStreamProvider);
    final selectedCategory = ref.watch(exploreCategoryProvider);
    final recommendationsAsync = ref.watch(exploreRecommendationsProvider);

    // Automatically animate map to updated GPS coordinates
    ref.listen<AsyncValue<LatLng>>(locationStreamProvider, (prev, next) {
      next.whenData((loc) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: loc, zoom: 14.5),
          ),
        );
      });
    });

    final currentLoc = locationAsync.value ??
        const LatLng(AppConfig.defaultLat, AppConfig.defaultLng);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (AppConfig.useLiveMap)
              FloatingActionButton.small(
                heroTag: 'explore_map_toggle',
                backgroundColor: AppColors.surface,
                tooltip: _useMockMapFallback ? 'Switch to Live Map' : 'Switch to Vector Map',
                onPressed: () {
                  setState(() {
                    _useMockMapFallback = !_useMockMapFallback;
                  });
                },
                child: Icon(
                  _useMockMapFallback ? Icons.map_outlined : Icons.layers_outlined,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'explore_recenter',
              backgroundColor: AppColors.surface,
              onPressed: () async {
                ref.invalidate(locationStreamProvider);
                try {
                  final loc = await ref.read(locationServiceProvider).getCurrentLocation();
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: loc, zoom: 15.0),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) {
                    final String msg = e is LocationException ? e.message : 'Could not determine your location.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg),
                        backgroundColor: AppColors.error,
                        action: SnackBarAction(
                          label: 'Settings',
                          textColor: Colors.white,
                          onPressed: () {
                            if (e is LocationException &&
                                e.reason == LocationFailureReason.permissionPermanentlyDenied) {
                              ref.read(locationServiceProvider).openAppSettings();
                            } else {
                              ref.read(locationServiceProvider).openLocationSettings();
                            }
                          },
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Map Canvas (Live Google Map or Fallback Mock Vector Map)
          (AppConfig.useLiveMap && !_useMockMapFallback)
              ? _buildLiveMap(currentLoc, recommendationsAsync.value ?? [])
              : _buildMockMap(currentLoc, recommendationsAsync.value ?? []),

          // 2. Floating Top Search & Category Pills
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search destinations, attractions, or food...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(exploreCategoryProvider.notifier).state = 'All';
                                          },
                                        )
                                      : null,
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    ref.read(exploreCategoryProvider.notifier).state = val.trim();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categories
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: AppConstants.categories.length,
                        itemBuilder: (context, index) {
                          final cat = AppConstants.categories[index];
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('${AppConstants.categoryEmojis[cat] ?? ""} $cat'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  ref.read(exploreCategoryProvider.notifier).state = cat;
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Loading Indicator Pill
                    if (recommendationsAsync.isLoading) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Finding ${selectedCategory == "All" ? "places" : selectedCategory.toLowerCase()}...',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Recommendations Error Banner
                    if (recommendationsAsync.hasError) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Could not load places: ${recommendationsAsync.error.toString().replaceAll("Exception: ", "")}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                ref.invalidate(exploreRecommendationsProvider);
                              },
                              child: const Text(
                                'RETRY',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Empty places banner
                    if (recommendationsAsync.hasValue && (recommendationsAsync.value?.isEmpty ?? false)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_off_rounded, color: AppColors.accent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No places found for "$selectedCategory". Try selecting another category.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                ref.read(exploreCategoryProvider.notifier).state = 'All';
                              },
                              child: const Text(
                                'SHOW ALL',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Location Error Banner (shown when GPS or permissions are unavailable)
                    if (locationAsync.hasError) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.6)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                locationAsync.error is LocationException
                                    ? (locationAsync.error as LocationException).message
                                    : 'Location is unavailable. Enable GPS to explore places around you.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                final err = locationAsync.error;
                                if (err is LocationException &&
                                    err.reason == LocationFailureReason.permissionPermanentlyDenied) {
                                  ref.read(locationServiceProvider).openAppSettings();
                                } else {
                                  ref.read(locationServiceProvider).openLocationSettings();
                                }
                              },
                              child: const Text(
                                'SETTINGS',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Swipeable / Bottom Recommendation Card Preview
          if (_selectedPlace != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 84), // FAB offset
                child: _buildBottomPreviewCard(_selectedPlace!),
              ),
            ),
        ],
      ),
    );
  }

  // ── Live Google Map ────────────────────────────────
  Widget _buildLiveMap(LatLng userLoc, List<dynamic> recommendations) {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('user_location'),
        position: userLoc,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    };

    for (var rec in recommendations) {
      final place = rec.place;
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: place.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            setState(() {
              _selectedPlace = place;
            });
          },
        ),
      );
    }

    const darkMapStyle = '''[
      {"elementType":"geometry","stylers":[{"color":"#212121"}]},
      {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
      {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
      {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
      {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
      {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
      {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
      {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
      {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
      {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
      {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
      {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
      {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
      {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
      {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
      {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
      {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
      {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
      {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
      {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
      {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
    ]''';

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: userLoc,
        zoom: 14.0,
      ),
      mapType: MapType.normal,
      style: darkMapStyle,
      onMapCreated: (controller) {
        _mapController = controller;
      },
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onTap: (_) {
        setState(() {
          _selectedPlace = null;
        });
      },
    );
  }

  // ── Mock Map Simulation (Vector Design) ─────────────
  Widget _buildMockMap(LatLng userLoc, List<dynamic> recommendations) {
    return Container(
      color: const Color(0xFF0F1E24), // Sleek custom dark canvas background
      child: Stack(
        children: [
          // Simulated Grid/Gridlines
          Positioned.fill(
            child: GridPaper(
              color: Colors.white.withValues(alpha: 0.02),
              divisions: 2,
              subdivisions: 1,
            ),
          ),
          // Water Body representation (Diagonal Vector Circle)
          Positioned(
            right: -100,
            top: 200,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Central Landmark representation (Fort)
          Positioned(
            left: 80,
            bottom: 220,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),

          // User Location Pin
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location, color: AppColors.primary, size: 28),
                SizedBox(height: 4),
                Card(
                  color: AppColors.primary,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'You',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Render Nearby Recommendations Pins (Absolute Spaced offsets)
          ...List.generate(recommendations.length, (index) {
            final rec = recommendations[index];
            final place = rec.place;
            final isSelected = _selectedPlace?.id == place.id;

            // Generate offset based on indexes
            final double dx = 60.0 * (index % 3 + 1) * (index.isEven ? 1 : -0.8);
            final double dy = 80.0 * (index % 2 + 1) * (index.isOdd ? 1 : -0.7);

            return Center(
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlace = place;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isSelected ? AppColors.accent : Colors.redAccent,
                        size: isSelected ? 42 : 32,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Text(
                          place.name.split(' ').first,
                          style: TextStyle(
                            color: isSelected ? AppColors.textPrimary : AppColors.textPrimary,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Place Preview Bottom Card ─────────────────────
  Widget _buildBottomPreviewCard(Place place) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 128,
        child: Row(
          children: [
            // Dummy photo thumbnail
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    place.name,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(place.rating?.toStringAsFixed(1) ?? 'N/A', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 8),
                      Text(
                        '·  ${place.distanceKm?.toStringAsFixed(1) ?? "0.0"} km away',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.formattedAddress,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_outlined, color: AppColors.primary),
                        onPressed: () => context.push('/place/${place.id}', extra: place),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
