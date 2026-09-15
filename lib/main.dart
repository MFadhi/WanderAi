import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permission early so geolocator works on first frame.
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    }
  } catch (_) {
    // Ignore errors during startup permission check; handled per-feature.
  }

  runApp(
    const ProviderScope(
      child: WanderApp(),
    ),
  );
}

class WanderApp extends StatelessWidget {
  const WanderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WanderAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // Premium Dark Theme
      routerConfig: appRouter,
    );
  }
}
