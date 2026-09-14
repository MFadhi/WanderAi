import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/place_model.dart';
import '../../shared/providers/app_providers.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPlaces = ref.watch(savedPlacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Places'),
      ),
      body: savedPlaces.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: savedPlaces.length,
              itemBuilder: (context, index) {
                final place = savedPlaces[index];
                return _buildSavedPlaceCard(context, place, ref);
              },
            ),
    );
  }

  Widget _buildSavedPlaceCard(BuildContext context, Place place, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/place/${place.id}', extra: place),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail container
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),

                // Place Details Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            place.rating?.toStringAsFixed(1) ?? 'N/A',
                            style: AppTextStyles.bodySmall,
                          ),
                          if (place.distanceKm != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '·  ${place.distanceKm!.toStringAsFixed(1)} km',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        place.formattedAddress,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Favorite Toggle Button
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    ref.read(savedPlacesProvider.notifier).toggleSave(place);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border,
                color: AppColors.textMuted,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No saved places yet',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'When you discover recommendations or routes you love, tap the heart button to bookmark them here.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
