import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/constants.dart';
import '../../shared/models/itinerary_model.dart';
import '../../shared/providers/app_providers.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  String _selectedDuration = 'Half Day';
  String _selectedBudget = '₹1,000';
  String _selectedStyle = 'Balanced';
  String _selectedTransport = 'TWO_WHEELER';

  bool _isConfiguring = true;

  @override
  Widget build(BuildContext context) {
    final itineraryState = ref.watch(itineraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trip Planner'),
        actions: [
          if (!_isConfiguring)
            IconButton(
              icon: const Icon(Icons.edit_note, color: AppColors.primary),
              onPressed: () {
                setState(() {
                  _isConfiguring = true;
                });
              },
            ),
        ],
      ),
      body: _isConfiguring
          ? _buildConfigurationForm()
          : itineraryState.isLoading
              ? _buildLoader()
              : itineraryState.errorMessage != null
                  ? _buildError(itineraryState.errorMessage!)
                  : itineraryState.itinerary != null
                      ? _buildItineraryTimeline(itineraryState.itinerary!)
                      : _buildConfigurationForm(),
    );
  }

  // ── Configuration Form ──────────────────────────────
  Widget _buildConfigurationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize Your Adventure',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Define your parameters, and Gemini will map out an optimized, personalized itinerary.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          // Duration Selector
          Text('Select Available Duration', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.tripDurations.map((duration) {
              final isSelected = _selectedDuration == duration;
              return ChoiceChip(
                label: Text(duration),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedDuration = duration;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Budget Selector
          Text('Select Budget Range', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.budgetOptions.map((budget) {
              final isSelected = _selectedBudget == budget;
              return ChoiceChip(
                label: Text(budget),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedBudget = budget;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Travel Style
          Text('Preferred Travel Pace', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: AppConstants.travelStyles.map((style) {
              final isSelected = _selectedStyle == style;
              final emoji = AppConstants.travelStyleEmojis[style] ?? '';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$emoji $style'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStyle = style;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Transport Mode
          Text('Primary Transportation', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['WALK', 'TWO_WHEELER', 'DRIVE', 'TRANSIT'].map((modeStr) {
              final isSelected = _selectedTransport == modeStr;
              final label = AppConstants.transportLabels[modeStr] ?? modeStr;
              final emoji = AppConstants.transportEmojis[modeStr] ?? '🛵';
              return ChoiceChip(
                label: Text('$emoji $label'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTransport = modeStr;
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _triggerPlanGeneration,
              child: const Text('Generate AI Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerPlanGeneration() async {
    setState(() {
      _isConfiguring = false;
    });

    // Update preferences in riverpod provider before generation
    final currentPrefs = ref.read(userPreferencesProvider);
    final updatedPrefs = currentPrefs.copyWith(
      maxBudget: AppConstants.budgetValues[_selectedBudget] ?? 500,
      preferredTransport: _selectedTransport,
      travelStyle: _selectedStyle,
    );
    await ref.read(userPreferencesProvider.notifier).updatePreferences(updatedPrefs);

    // Call notifier to generate Itinerary
    ref.read(itineraryProvider.notifier).generateItinerary(_selectedDuration);
  }

  // ── Timeline Viewer ─────────────────────────────────
  Widget _buildItineraryTimeline(Itinerary itinerary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Info Card
          Card(
            color: AppColors.primaryContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itinerary.title,
                          style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itinerary.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Vertical timeline list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itinerary.stops.length,
            itemBuilder: (context, index) {
              final stop = itinerary.stops[index];
              final isLast = index == itinerary.stops.length - 1;
              return _buildTimelineItem(stop, isLast);
            },
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _isConfiguring = true;
                });
              },
              child: const Text('Replan Itinerary'),
            ),
          ),
          const SizedBox(height: 48), // Padding spacing
        ],
      ),
    );
  }

  Widget _buildTimelineItem(ItineraryStop stop, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Timing and Line
          Column(
            children: [
              // Timestamp box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stop.time,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              // Line representation
              Expanded(
                child: isLast
                    ? const SizedBox.shrink()
                    : Container(
                        width: 2,
                        color: AppColors.border,
                      ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Right side: Stop card content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stop Place Card
                  GestureDetector(
                    onTap: () => context.push('/place/${stop.place.id}', extra: stop.place),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    stop.place.name,
                                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stop.activity,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),

                            // AI try item highlight
                            if (stop.aiPick != null) ...[
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'AI Pick: ${stop.aiPick}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Travel Safety warnings
                            if (stop.awarenessItems.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...stop.awarenessItems.map((warn) => Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.orange.shade800, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            warn,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.orange.shade800,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Connection routing line (if there is a next stop)
                  if (!isLast && stop.transportToNext != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Text(stop.transportToNext!.mode.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Transit: ${stop.transportToNext!.distanceKm.toStringAsFixed(1)} km,  ${stop.transportToNext!.durationMinutes} mins',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Common UI State helpers
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('WanderAI is planning your schedule...', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Computing routes and reasoning over local spots', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildError(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(errorMsg, style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isConfiguring = true;
                });
              },
              child: const Text('Back to Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
