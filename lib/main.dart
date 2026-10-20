import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Note: .env file not found or failed to load: $e');
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
