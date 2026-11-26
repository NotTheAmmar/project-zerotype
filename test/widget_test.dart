import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_zerotype/app.dart';
import 'package:project_zerotype/controllers/capture_controller.dart';
import 'package:project_zerotype/controllers/catalog_controller.dart';
import 'package:project_zerotype/controllers/language_controller.dart';
import 'package:project_zerotype/controllers/pricing_controller.dart';
import 'package:project_zerotype/controllers/voice_controller.dart';
import 'package:project_zerotype/services/api_service.dart';
import 'package:project_zerotype/services/audio_service.dart';
import 'package:project_zerotype/services/image_service.dart';
import 'package:project_zerotype/services/storage_service.dart';
import 'package:project_zerotype/views/widgets/bilingual_text.dart';

void main() {
  testWidgets('BazaarSetu app smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'bazaarsetu_user_language': 'hi',
      'bazaarsetu_language_setup_done': true,
    });

    final imageService = ImageService();
    final audioService = AudioService();
    final storageService = StorageService();
    final apiService = ApiService();
    final languageCtrl = LanguageController();
    await languageCtrl.loadLanguagePreference();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageCtrl),
          ChangeNotifierProvider(
            create: (_) => CaptureController(imageService: imageService),
          ),
          ChangeNotifierProvider(
            create: (_) => VoiceController(audioService: audioService),
          ),
          ChangeNotifierProvider(
            create: (_) => CatalogController(
              apiService: apiService,
              audioService: audioService,
              storageService: storageService,
            ),
          ),
          ChangeNotifierProvider(create: (_) => PricingController()),
        ],
        child: const BazaarSetuApp(),
      ),
    );

    await tester.pump();

    // Verify BazaarSetu branding and Karigar Hub are rendered
    expect(find.text('BazaarSetu'), findsOneWidget);
    expect(find.text('Karigar Hub'), findsOneWidget);
  });

  testWidgets('BazaarSetu first launch opens language selection screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final imageService = ImageService();
    final audioService = AudioService();
    final storageService = StorageService();
    final apiService = ApiService();
    final languageCtrl = LanguageController();
    await languageCtrl.loadLanguagePreference();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageCtrl),
          ChangeNotifierProvider(
            create: (_) => CaptureController(imageService: imageService),
          ),
          ChangeNotifierProvider(
            create: (_) => VoiceController(audioService: audioService),
          ),
          ChangeNotifierProvider(
            create: (_) => CatalogController(
              apiService: apiService,
              audioService: audioService,
              storageService: storageService,
            ),
          ),
          ChangeNotifierProvider(create: (_) => PricingController()),
        ],
        child: const BazaarSetuApp(),
      ),
    );

    await tester.pump();

    // Verify Language selection title and mode options are shown on first launch
    expect(
      find.text('Choose Your Language Display\nअपनी भाषा चुनें'),
      findsOneWidget,
    );
    expect(find.text('Single Language • एक भाषा'), findsOneWidget);
    expect(find.text('Bilingual (2) • दो भाषाएँ (2)'), findsOneWidget);
  });

  testWidgets('BilingualText switches between single and bilingual modes', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final languageCtrl = LanguageController(autoLoad: false);
    await languageCtrl.setLanguagePreferences(
      mode: LanguageDisplayMode.single,
      primaryCode: 'ta',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: languageCtrl,
        child: const MaterialApp(
          home: Scaffold(
            body: BilingualText(
              english: 'Clay Pot',
              local: 'मिट्टी का घड़ा',
              translations: {'en': 'Clay Pot', 'hi': 'मिट्टी का घड़ा', 'ta': 'மண் பானை'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('மண் பானை'), findsOneWidget);
    expect(find.text('Clay Pot'), findsNothing);

    await languageCtrl.setLanguagePreferences(
      mode: LanguageDisplayMode.bilingual,
      primaryCode: 'en',
      secondaryCode: 'ta',
    );
    await tester.pump();

    expect(find.text('Clay Pot'), findsOneWidget);
    expect(find.text('மண் பானை'), findsOneWidget);
  });
}
