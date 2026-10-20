import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/errors/exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/constants.dart';
import '../../shared/models/recommendation_model.dart';
import '../../shared/providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(homeCategoryProvider);
    final recommendationListAsync = ref.watch(homeRecommendationListProvider);
    final cityNameAsync = ref.watch(currentCityNameProvider);
    final locationAsync = ref.watch(locationStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(locationStreamProvider);
            ref.invalidate(currentCityNameProvider);
            ref.invalidate(homeRecommendationProvider);
            ref.invalidate(recommendationListProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, 👋',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What do you want to explore?',
                          style: AppTextStyles.headlineMedium,
                        ),
                      ],
                    ),
                    // Preferences Config Button
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.primary),
                      onPressed: () => context.push('/onboarding'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location Pill
                InkWell(
                  onTap: () {
                    ref.invalidate(locationStreamProvider);
                    ref.invalidate(currentCityNameProvider);
                    ref.invalidate(homeRecommendationProvider);
                    ref.invalidate(recommendationListProvider);
                    if (locationAsync.hasError) {
                      ref.read(locationServiceProvider).openLocationSettings();
                    }
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: locationAsync.hasError
                          ? AppColors.error.withValues(alpha: 0.12)
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: locationAsync.hasError ? AppColors.error : AppColors.border,
                        width: locationAsync.hasError ? 1.0 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          locationAsync.hasError ? Icons.location_off : Icons.location_on,
                          color: locationAsync.hasError ? AppColors.error : AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          locationAsync.hasError
                              ? 'Location Disabled — Tap to fix'
                              : (cityNameAsync.value ?? 'Locating...'),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: locationAsync.hasError ? AppColors.error : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.refresh, size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),

                // Location Error Card (shown when GPS or permissions are unavailable)
                if (locationAsync.hasError) ...[
                  const SizedBox(height: 16),
                  _buildLocationErrorCard(context, locationAsync.error, ref),
                ],

                const SizedBox(height: 24),

                // Explore Nearby Categories (Switches)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore Nearby',
                      style: AppTextStyles.titleLarge,
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
                      label: const Text(
                        'View Map',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () {
                        ref.read(exploreCategoryProvider.notifier).state = selectedCategory;
                        ref.read(bottomNavIndexProvider.notifier).state = 1;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCategoriesList(context, ref),

                const SizedBox(height: 24),

                // Featured Cards Section for Selected Category
                Row(
                  children: [
                    Text(
                      selectedCategory == 'All'
                          ? '✨ Best For You Right Now'
                          : '✨ Best in $selectedCategory',
                      style: AppTextStyles.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                recommendationListAsync.when(
                  data: (recs) {
                    if (recs.isEmpty) {
                      return _buildEmptyState();
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < recs.length; i++) ...[
                          _buildFeaturedCard(context, recs[i], ref, isTop: i == 0),
                          if (i < recs.length - 1) const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                  loading: () => _buildShimmerLoader(),
                  error: (err, _) => _buildErrorState(err, ref),
                ),

                const SizedBox(height: 100), // Bottom padding for Ask AI FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Recommendation rec, WidgetRef ref, {bool isTop = false}) {
    final place = rec.place;
    final transportOpt = rec.recommendedOption;
    final savedPlaces = ref.watch(savedPlacesProvider);
    final isSaved = savedPlaces.any((p) => p.id == place.id);

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Stack(
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.9),
                      AppColors.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.name,
                      style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          place.rating?.toStringAsFixed(1) ?? 'N/A',
                          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·  ${place.distanceKm?.toStringAsFixed(1) ?? "0.0"} km',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '·  ${place.priceLevel?.symbol ?? "₹₹"}',
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Match Score Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${rec.matchScore}% Match',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              // Bookmark Button
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () async {
                      final wasSaved = isSaved;
                      await ref.read(savedPlacesProvider.notifier).toggleSave(place);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              wasSaved
                                  ? 'Removed "${place.name}" from saved places'
                                  : 'Saved "${place.name}" to your places! ❤️',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highlight Specs
                Row(
                  children: [
                    if (rec.tryThis != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            const Text('🍛 ', style: TextStyle(fontSize: 18)),
                            Expanded(
                              child: Text(
                                'Try: ${rec.tryThis}',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('🛵 ', style: TextStyle(fontSize: 18)),
                          Text(
                            'Transit: ${transportOpt?.durationMinutes ?? 0} min',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Why matches
                const Text(
                  'Why this matches you',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  rec.reason,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                // Be aware
                if (rec.awarenessItems.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Be aware',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...rec.awarenessItems.take(2).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                item,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),

        // Action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/place/${place.id}', extra: place),
                    child: const Text('Explore Recommendation'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(homeCategoryProvider);

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.categories.length,
        itemBuilder: (context, index) {
          final cat = AppConstants.categories[index];
          final emoji = AppConstants.categoryEmojis[cat] ?? '';
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Text(emoji),
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(homeCategoryProvider.notifier).state = cat;
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Card(
        child: Container(
          height: 380,
          width: double.infinity,
          color: AppColors.card,
        ),
      ),
    );
  }

  Widget _buildLocationErrorCard(BuildContext context, Object? error, WidgetRef ref) {
    final String message;
    final bool isPermanentlyDenied;
    if (error is LocationException) {
      message = error.message;
      isPermanentlyDenied = error.reason == LocationFailureReason.permissionPermanentlyDenied;
    } else {
      message = 'Location access is required to find places and experiences near you.';
      isPermanentlyDenied = false;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Location Unavailable',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.settings, size: 16),
                label: Text(isPermanentlyDenied ? 'App Settings' : 'Enable Location'),
                onPressed: () {
                  final loc = ref.read(locationServiceProvider);
                  if (isPermanentlyDenied) {
                    loc.openAppSettings();
                  } else {
                    loc.openLocationSettings();
                  }
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                onPressed: () {
                  ref.invalidate(locationStreamProvider);
                  ref.invalidate(currentCityNameProvider);
                  ref.invalidate(recommendationListProvider);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object err, WidgetRef ref) {
    final isLocationError = err is LocationException ||
        err.toString().toLowerCase().contains('location') ||
        err.toString().toLowerCase().contains('gps');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLocationError ? Icons.location_off_rounded : Icons.error_outline,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                isLocationError ? 'Location Access Required' : 'Something went wrong',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            err is LocationException
                ? err.message
                : (isLocationError
                    ? 'WanderAI needs your location to recommend places and activities near you.'
                    : 'I couldn\'t find enough information to make a reliable recommendation. Try checking your internet or expanding your search parameters.'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (isLocationError)
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Open Settings'),
                  onPressed: () => ref.read(locationServiceProvider).openLocationSettings(),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  onPressed: () {
                    ref.invalidate(locationStreamProvider);
                    ref.invalidate(recommendationListProvider);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'No matches found',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your preference filters (budget or time limit) to discover options.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
