import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sih_26_kalakriti/app.dart';
import 'package:sih_26_kalakriti/controllers/capture_controller.dart';
import 'package:sih_26_kalakriti/controllers/catalog_controller.dart';
import 'package:sih_26_kalakriti/controllers/pricing_controller.dart';
import 'package:sih_26_kalakriti/controllers/voice_controller.dart';
import 'package:sih_26_kalakriti/services/api_service.dart';
import 'package:sih_26_kalakriti/services/audio_service.dart';
import 'package:sih_26_kalakriti/services/image_service.dart';
import 'package:sih_26_kalakriti/services/storage_service.dart';

void main() {
  testWidgets('BazaarSetu app smoke test', (WidgetTester tester) async {
    final imageService = ImageService();
    final audioService = AudioService();
    final storageService = StorageService();
    final apiService = ApiService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
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
        child: const KalaKritiApp(),
      ),
    );

    await tester.pump();

    // Verify BazaarSetu branding and Karigar Hub are rendered
    expect(find.text('BazaarSetu'), findsOneWidget);
    expect(find.text('Karigar Hub'), findsOneWidget);
  });
}
