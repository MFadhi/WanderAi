import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/constants.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/details/place_details_screen.dart';
import '../../features/navigation/navigation_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/models/place_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return SplashScreen(
          onComplete: () async {
            final prefs = await SharedPreferences.getInstance();
            final onboardingDone =
                prefs.getBool(AppConstants.prefKeyOnboardingDone) ?? false;
            if (context.mounted) {
              context.go(onboardingDone ? '/' : '/onboarding');
            }
          },
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const NavigationShell();
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingScreen();
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (BuildContext context, GoRouterState state) {
        return const ChatScreen();
      },
    ),
    GoRoute(
      path: '/place/:id',
      builder: (BuildContext context, GoRouterState state) {
        final place = state.extra as Place?;
        final id = state.pathParameters['id'] ?? '';
        return PlaceDetailsScreen(placeId: id, place: place);
      },
    ),
  ],
);
