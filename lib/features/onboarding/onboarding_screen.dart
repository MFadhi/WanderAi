import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/constants.dart';
import '../../shared/models/user_preferences_model.dart';
import '../../shared/providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Temporary onboarding state
  final List<String> _selectedInterests = ['Food', 'Nature'];
  double _budget = 500.0;
  double _hours = 3.0;
  String _transport = 'TWO_WHEELER';
  String _style = 'Balanced';
  bool _vegetarian = false;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyOnboardingDone, true);

    // Save preferences to Riverpod
    final userPrefs = UserPreferences(
      interests: _selectedInterests,
      maxBudget: _budget,
      preferredTransport: _transport,
      availableHours: _hours,
      dietaryPreferences: _vegetarian ? ['Vegetarian'] : [],
      vegetarian: _vegetarian,
      travelStyle: _style,
    );

    await ref.read(userPreferencesProvider.notifier).updatePreferences(userPrefs);

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildIntroPage(),
                  _buildInterestsPage(),
                  _buildBudgetAndTimePage(),
                  _buildTransportAndStylePage(),
                ],
              ),
            ),
            // Footer Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome ────────────────────────────────
  Widget _buildIntroPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Meet WanderAI',
            style: AppTextStyles.displaySmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Your premium travel assistant. WanderAI reasons over Google Maps data, ratings, reviews, and your preferences to decide the absolute best thing for you to do right now.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildBulletItem(Icons.location_on, 'Location-aware recommendations'),
          _buildBulletItem(Icons.route, 'Smart multi-mode travel routing'),
          _buildBulletItem(Icons.restaurant, 'AI-curated food and local tips'),
        ],
      ),
    );
  }

  Widget _buildBulletItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  // ── Page 2: Interests ──────────────────────────────
  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Interests', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'What do you like to explore when visiting new places?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: kAllInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                final emoji = AppConstants.categoryEmojis[interest] ?? '';
                return FilterChip(
                  label: Text('$emoji $interest'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          // Vegetarian flag
          SwitchListTile(
            title: const Text('🍛 Show Vegetarian Only'),
            subtitle: const Text('Filter restaurant recommendations to pure veg spots'),
            value: _vegetarian,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _vegetarian = val;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── Page 3: Budget & Time ─────────────────────────
  Widget _buildBudgetAndTimePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget & Available Time', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 24),
          // Budget Slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Maximum Budget', style: AppTextStyles.titleMedium),
                      Text(
                        _budget >= 2000 ? '₹2000+' : '₹${_budget.toStringAsFixed(0)}',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _budget,
                    min: 0,
                    max: 2000,
                    divisions: 10,
                    onChanged: (val) {
                      setState(() {
                        _budget = val;
                      });
                    },
                  ),
                  Text(
                    'Per activity cost, including food and ticket prices.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Time Slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Hours', style: AppTextStyles.titleMedium),
                      Text(
                        '${_hours.toStringAsFixed(1)} h',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: _hours,
                    min: 1,
                    max: 8,
                    divisions: 7,
                    onChanged: (val) {
                      setState(() {
                        _hours = val;
                      });
                    },
                  ),
                  Text(
                    'How much time do you have to explore right now?',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 4: Transport & Style ─────────────────────
  Widget _buildTransportAndStylePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Travel Preferences', style: AppTextStyles.headlineLarge),
          const SizedBox(height: 24),
          // Transport
          Text('Preferred Transport Mode', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['WALK', 'BICYCLE', 'TWO_WHEELER', 'DRIVE', 'TRANSIT'].map((modeStr) {
              final isSelected = _transport == modeStr;
              final label = AppConstants.transportLabels[modeStr] ?? modeStr;
              final emoji = AppConstants.transportEmojis[modeStr] ?? '🚗';
              return ChoiceChip(
                label: Text('$emoji $label'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _transport = modeStr;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Travel Style
          Text('Preferred Pace Style', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: AppConstants.travelStyles.map((styleStr) {
              final isSelected = _style == styleStr;
              final emoji = AppConstants.travelStyleEmojis[styleStr] ?? '';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$emoji $styleStr'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _style = styleStr;
                        });
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
