import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'views/screens/explore_screen.dart';
import 'views/screens/capture_screen.dart';
import 'views/screens/catalog_screen.dart';
import 'views/screens/processing_screen.dart';
import 'views/screens/voice_screen.dart';
import 'views/screens/welcome_screen.dart';

class BazaarSetuApp extends StatelessWidget {
  const BazaarSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BazaarSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.explore,
      routes: {
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.explore: (_) => const ExploreScreen(),
        AppRoutes.capture: (_) => const CaptureScreen(),
        AppRoutes.voice: (_) => const VoiceScreen(),
        AppRoutes.processing: (_) => const ProcessingScreen(),
        AppRoutes.catalog: (_) => const CatalogScreen(),
      },
    );
  }
}
