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
          ChangeNotifierProvider(
            create: (_) => PricingController(),
          ),
        ],
        child: const BazaarSetuApp(),
      ),
    );

    await tester.pump();

    // Verify BazaarSetu branding and Karigar Hub are rendered
    expect(find.text('BazaarSetu'), findsOneWidget);
    expect(find.text('Karigar Hub'), findsOneWidget);
  });
}
