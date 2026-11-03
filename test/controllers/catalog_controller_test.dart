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
  });
}
