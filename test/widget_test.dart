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
import 'package:project_zerotype/models/catalog_item.dart';
import 'package:project_zerotype/models/craft_attributes.dart';
import 'package:project_zerotype/models/pricing_corridor.dart';
import 'package:project_zerotype/services/api_service.dart';
import 'package:project_zerotype/services/audio_service.dart';
import 'package:project_zerotype/services/image_service.dart';
import 'package:project_zerotype/services/storage_service.dart';
import 'package:project_zerotype/views/screens/catalog_screen.dart';
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

    // Verify BazaarSetu branding and Karigar Hub header are rendered (no Voice test toggle)
    expect(find.text('BazaarSetu'), findsOneWidget);
    expect(find.text('Karigar Hub • कारीगर केंद्र'), findsOneWidget);
    expect(find.text('Voice Mode (Test)'), findsNothing);
    expect(find.text('Bhashini'), findsNothing);
    expect(find.text('Whisper'), findsNothing);
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

  testWidgets('CatalogScreen shows Crafting Time and hides edit controls when published', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'bazaarsetu_user_language': 'en',
      'bazaarsetu_language_setup_done': true,
    });
    final languageCtrl = LanguageController(autoLoad: false);
    await languageCtrl.setLanguagePreferences(
      mode: LanguageDisplayMode.single,
      primaryCode: 'en',
    );
    final catalogCtrl = CatalogController(
      apiService: MockApiService(),
      audioService: AudioService(),
      storageService: StorageService(),
    );
    addTearDown(catalogCtrl.dispose);

    final draftItem = CatalogItem(
      id: 'craft_test_1',
      createdAt: DateTime(2026, 11, 27),
      status: CatalogStatus.draft,
      titleEn: 'Clay Vase',
      titleHi: 'मिट्टी का फूलदान',
      descriptionEn: 'Handcrafted terracotta vase.',
      descriptionHi: 'हस्तनिर्मित टेराकोटा फूलदान।',
      craftAttributes: const CraftAttributes(
        category: 'Pottery',
        materials: ['Clay'],
        laborDays: 2,
      ),
      pricing: PricingCorridor.compute(
        rawMaterialCost: 100,
        laborDays: 2,
        sellerProposedPrice: 350,
      ),
    );
    catalogCtrl.setItem(draftItem);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageCtrl),
          ChangeNotifierProvider.value(value: catalogCtrl),
          ChangeNotifierProvider(create: (_) => PricingController()),
        ],
        child: const MaterialApp(home: CatalogScreen()),
      ),
    );
    await tester.pump();

    // Draft renders Voice Edit button, edit pencil, Manual Edit, and Crafting Time spec
    expect(find.text('Voice Edit'), findsOneWidget);
    expect(find.byTooltip('Edit by voice or values'), findsOneWidget);
    expect(find.byTooltip('Manual Edit'), findsOneWidget);
    expect(find.text('Crafting Time'), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);

    // Once published, Voice Edit / Manual Edit / edit pencil are hidden
    catalogCtrl.setItem(draftItem.copyWith(status: CatalogStatus.published));
    await tester.pump();

    expect(find.text('Voice Edit'), findsNothing);
    expect(find.byTooltip('Edit by voice or values'), findsNothing);
    expect(find.byTooltip('Manual Edit'), findsNothing);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);
  });
}
