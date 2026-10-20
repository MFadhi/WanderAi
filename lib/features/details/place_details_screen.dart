import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/place_model.dart';
import '../../shared/models/recommendation_model.dart';
import '../../shared/models/transport_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/services/mock_data_service.dart';

class PlaceDetailsScreen extends ConsumerStatefulWidget {
  final String placeId;
  final Place? place;

  const PlaceDetailsScreen({
    super.key,
    required this.placeId,
    this.place,
  });

  @override
  ConsumerState<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends ConsumerState<PlaceDetailsScreen> {
  late Place _place;
  bool _isLoading = true;
  String? _error;
  Recommendation? _recommendation;
  bool _isRanking = true;

  @override
  void initState() {
    super.initState();
    _loadDetailsAndRank();
  }

  Future<void> _loadDetailsAndRank() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Resolve Place details
      if (widget.place != null) {
        _place = widget.place!;
      } else {
        // Fetch place details from API/Mock
        _place = MockDataService.places.firstWhere(
          (p) => p.id == widget.placeId,
          orElse: () => MockDataService.places.first,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // 2. Perform AI Ranking
      _generateAiRanking();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load details: $e';
      });
    }
  }

  Future<void> _generateAiRanking() async {
    setState(() {
      _isRanking = true;
    });

    try {
      final gemini = ref.read(geminiServiceProvider);
      final preferences = ref.read(userPreferencesProvider);

      // Compute routes
      List<TransportOption> routes = MockDataService.mockTransportOptions(_place.distanceKm ?? 2.0);

      // Generate recommendation
      final rec = await gemini.rankRecommendation(
        place: _place,
        preferences: preferences,
        transportOptions: routes,
      );

      setState(() {
        _recommendation = rec;
        _isRanking = false;
      });
    } catch (_) {
      setState(() {
        _isRanking = false;
      });
    }
  }

  Future<void> _launchNavigation() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${_place.location.latitude},${_place.location.longitude}&query_place_id=${_place.id}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final savedPlaces = ref.watch(savedPlacesProvider);
    final isSaved = savedPlaces.any((p) => p.id == _place.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Silver AppBar with Photo/Thumbnail ─────────
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: isSaved ? Colors.red : Colors.white),
                onPressed: () async {
                  final wasSaved = isSaved;
                  await ref.read(savedPlacesProvider.notifier).toggleSave(_place);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasSaved
                              ? 'Removed "${_place.name}" from saved places'
                              : 'Saved "${_place.name}" to your places! ❤️',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _place.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.9),
                          AppColors.primary,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, size: 64, color: Colors.white24),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Details Body ───────────────────────────────
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating + Specs
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _place.rating?.toStringAsFixed(1) ?? 'N/A',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${_place.userRatingsTotal ?? 0} reviews)',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        if (_place.distanceKm != null) ...[
                          const Icon(Icons.directions_walk, color: AppColors.primary, size: 18),
                          const SizedBox(width: 4),
                          Text('${_place.distanceKm!.toStringAsFixed(1)} km', style: AppTextStyles.bodyMedium),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _place.formattedAddress,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const Divider(height: 32),

                    // ── Section 1: AI Recommendation details ────
                    _buildAiRecommendationSection(),

                    const Divider(height: 32),

                    // ── Section 2: Google Reviews ──────────────
                    Text('💬 What Visitors Say (Google Maps Data)', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    if (_place.reviews.isEmpty)
                      Text('No Google reviews available for this place.', style: AppTextStyles.bodyMedium)
                    else
                      ..._place.reviews.take(3).map((review) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 0,
                              color: AppColors.inputFill,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.primaryContainer,
                                          radius: 12,
                                          child: const Icon(Icons.person, size: 12, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            review.authorName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (index) {
                                            return Icon(
                                              Icons.star,
                                              size: 10,
                                              color: index < review.rating ? Colors.amber : Colors.grey,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      review.text,
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildAiRecommendationSection() {
    if (_isRanking) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('WanderAI is analyzing details & reviews...', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }

    if (_recommendation == null) {
      return const SizedBox.shrink();
    }

    final rec = _recommendation!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Header card
        Card(
          color: AppColors.primaryContainer.withValues(alpha: 0.3),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accent, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recommendation • ${rec.matchScore}% Match',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.reason,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // AI try items
        if (rec.tryThis != null) ...[
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text('🍽️ AI Picks / Specialty', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Try: ${rec.tryThis}',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimated Budget: ${rec.estimatedBudget}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
        ],

        // Review insights positive vs warning
        Row(
          children: [
            const Icon(Icons.comment_bank_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('💬 Visitor Sentiment Summary', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('People Love', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                  const SizedBox(height: 6),
                  ...rec.reviewInsights.positive.take(3).map((item) => Text('✓ $item', style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Be Aware', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                  const SizedBox(height: 6),
                  ...rec.reviewInsights.negative.take(3).map((item) => Text('• $item', style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Travel Awareness Warnings
        if (rec.awarenessItems.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('🛡️ Travel Awareness', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...rec.awarenessItems.map((item) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_outlined, color: Colors.orange.shade800, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Transport breakdown
        Row(
          children: [
            const Icon(Icons.directions_run_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('🛵 Travel Mode Options', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          children: rec.transportOptions.map((opt) {
            final isRecommended = opt.mode.apiValue == rec.recommendedTransport;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isRecommended ? AppColors.primaryContainer.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRecommended ? AppColors.primary : AppColors.border,
                    width: isRecommended ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt.mode.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt.mode.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${opt.distanceKm.toStringAsFixed(1)} km  ·  ${opt.durationMinutes} min',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (isRecommended)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Best Way', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // Ask AI about this place
                ref.read(chatProvider.notifier).clearChat();
                ref.read(chatProvider.notifier).sendMessage('Tell me about ${_place.name}');
                context.push('/chat');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 16),
                  SizedBox(width: 8),
                  Text('Ask AI'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _launchNavigation,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Navigate'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
