import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/config/app_config.dart';
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
    final recommendationAsync = ref.watch(currentRecommendationProvider);
    final cityNameAsync = ref.watch(currentCityNameProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(locationStreamProvider);
            ref.invalidate(currentCityNameProvider);
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
                    ref.invalidate(recommendationListProvider);
                  },
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          cityNameAsync.value ?? AppConfig.defaultCityName,
                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.refresh, size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Featured Card Section
                Text(
                  '✨ Best For You Right Now',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 16),

                recommendationAsync.when(
                  data: (rec) {
                    if (rec == null) {
                      return _buildEmptyState();
                    }
                    return _buildFeaturedCard(context, rec, ref);
                  },
                  loading: () => _buildShimmerLoader(),
                  error: (err, _) => _buildErrorState(err.toString()),
                ),

                const SizedBox(height: 32),

                // Explore Nearby Categories
                Text(
                  'Explore Nearby',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildCategoriesList(context),
                const SizedBox(height: 48), // Bottom padding for FAB spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Recommendation rec, WidgetRef ref) {
    final place = rec.place;
    final transportOpt = rec.recommendedOption;
    final isSaved = ref.watch(savedPlacesProvider.notifier).isSaved(place.id);

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
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      ref.read(savedPlacesProvider.notifier).toggleSave(place);
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

  Widget _buildCategoriesList(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.categories.length,
        itemBuilder: (context, index) {
          final cat = AppConstants.categories[index];
          final emoji = AppConstants.categoryEmojis[cat] ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Text(emoji),
              label: Text(cat),
              onPressed: () {
                // For simplicity, we can let user filter by category,
                // or just trigger search with query.
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

  Widget _buildErrorState(String error) {
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
          const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Something went wrong',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'I couldn\'t find enough information to make a reliable recommendation. Try checking your internet or expanding your search parameters.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
