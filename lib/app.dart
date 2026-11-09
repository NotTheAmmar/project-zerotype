import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'controllers/language_controller.dart';
import 'views/screens/explore_screen.dart';
import 'views/screens/capture_screen.dart';
import 'views/screens/catalog_screen.dart';
import 'views/screens/language_selection_screen.dart';
import 'views/screens/processing_screen.dart';
import 'views/screens/voice_screen.dart';
import 'views/screens/welcome_screen.dart';

class BazaarSetuApp extends StatelessWidget {
  const BazaarSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langCtrl = context.watch<LanguageController>();

    return MaterialApp(
      title: 'BazaarSetu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: (!langCtrl.isLoaded || !langCtrl.isLanguageSetupDone)
          ? AppRoutes.languageSelection
          : AppRoutes.explore,
      routes: {
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.languageSelection: (_) => const LanguageSelectionScreen(isInitialSetup: true),
        AppRoutes.explore: (_) => const ExploreScreen(),
        AppRoutes.capture: (_) => const CaptureScreen(),
        AppRoutes.voice: (_) => const VoiceScreen(),
        AppRoutes.processing: (_) => const ProcessingScreen(),
        AppRoutes.catalog: (_) => const CatalogScreen(),
      },
    );
  }
}
