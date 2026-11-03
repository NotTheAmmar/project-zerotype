import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/controllers/catalog_controller.dart';
import 'package:project_zerotype/models/catalog_item.dart';
import 'package:project_zerotype/models/pricing_corridor.dart';
import 'package:project_zerotype/services/api_service.dart';
import 'package:project_zerotype/services/audio_service.dart';
import 'package:project_zerotype/services/storage_service.dart';

class FakeApiService implements ApiService {
  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    List<String>? audioPaths,
    String? manualDimensions,
    StageCallback? onStageComplete,
  }) async {
    return CatalogProcessResult(
      titleEn: 'Handmade Silk Shawl',
      titleHi: 'हस्तनिर्मित सिल्क शॉल',
      descriptionEn: 'Pure Chanderi silk with zari work',
      descriptionHi: 'शुद्ध चंदेरी रेशम ज़री कार्य सहित',
      pricing: PricingCorridor.compute(rawMaterialCost: 500, laborDays: 3),
    );
  }

  @override
  Future<String> transcribeAudio(String audioPath) async {
    return 'कीमत ₹650 कर दो';
  }

  @override
  Future<CatalogItem> updateCatalogWithInstruction({
    required CatalogItem currentItem,
    required String instruction,
  }) async {
    return currentItem.copyWith(
      pricing: PricingCorridor.compute(
        rawMaterialCost: currentItem.pricing?.rawMaterialCost ?? 100,
        laborDays: currentItem.pricing?.laborDays ?? 1,
        sellerProposedPrice: 650,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  }) async {
    return {'status': 'PUBLISHED', 'catalog_id': item.id};
  }
}

class FakeAudioService extends AudioService {
  @override
  Future<void> speakText(String hindiText) async {}

  @override
  Future<void> speakCatalogSummary({
    required String? titleHi,
    required int? fairPrice,
    required String? category,
    List<String>? materials,
    int? laborDays,
    String? descriptionHi,
  }) async {}

  @override
  Future<void> stopTts() async {}

  @override
  Future<void> dispose() async {}
}

class FakeStorageService extends StorageService {
  final List<CatalogItem> _saved = [];

  @override
  Future<List<CatalogItem>> loadCatalogs() async => _saved;

  @override
  Future<void> saveCatalog(CatalogItem item) async {
    _saved.add(item);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogController Tests', () {
    late FakeApiService apiService;
    late FakeAudioService audioService;
    late FakeStorageService storageService;
    late CatalogController controller;

    setUp(() {
      apiService = FakeApiService();
      audioService = FakeAudioService();
      storageService = FakeStorageService();
      controller = CatalogController(
        apiService: apiService,
        audioService: audioService,
        storageService: storageService,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial stage is notStarted and currentItem is null', () {
      expect(controller.stage, equals(ProcessingStage.notStarted));
      expect(controller.currentItem, isNull);
    });

    test('createFallbackDraft constructs valid draft preserving artisan photo and defaults', () async {
      await controller.createFallbackDraft(
        imagePath: '/tmp/artisan_craft.jpg',
        audioPath: '/tmp/artisan_voice.wav',
        category: 'Pottery',
      );

      expect(controller.stage, equals(ProcessingStage.done));
      expect(controller.currentItem, isNotNull);
      expect(controller.currentItem!.rawImagePath, equals('/tmp/artisan_craft.jpg'));
      expect(controller.currentItem!.titleHi, contains('हस्तनिर्मित'));
      expect(controller.currentItem!.craftAttributes?.category, equals('Pottery'));
      expect(controller.currentItem!.pricing?.fairPrice, greaterThan(0));
    });

    test('processCatalog pipeline executes stages and stores current item', () async {
      await controller.processCatalog(
        imagePath: '/tmp/image.jpg',
        audioPath: '/tmp/audio.wav',
      );

      expect(controller.stage, equals(ProcessingStage.done));
      expect(controller.currentItem, isNotNull);
      expect(controller.currentItem!.titleEn, equals('Handmade Silk Shawl'));
    });

    test('updateCurrentItem updates item and persists', () async {
      await controller.createFallbackDraft(imagePath: '/tmp/craft.jpg');
      final updated = controller.currentItem!.copyWith(
        titleHi: 'संशोधित मिट्टी का दीया',
      );

      await controller.updateCurrentItem(updated);
      expect(controller.currentItem!.titleHi, equals('संशोधित मिट्टी का दीया'));
    });

    test('applyVoiceUpdate invokes AI update and sets new corridor', () async {
      await controller.createFallbackDraft(imagePath: '/tmp/craft.jpg');
      await controller.applyVoiceUpdate('कीमत ₹650 कर दो');

      expect(controller.currentItem!.pricing?.sellerProposedPrice, equals(650));
      expect(controller.currentItem!.pricing?.fairPrice, equals(990));
    });
  });
}
