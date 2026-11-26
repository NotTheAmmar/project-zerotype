import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/controllers/catalog_controller.dart';
import 'package:project_zerotype/models/catalog_item.dart';
import 'package:project_zerotype/models/pricing_corridor.dart';
import 'package:project_zerotype/services/api_service.dart';
import 'package:project_zerotype/services/audio_service.dart';
import 'package:project_zerotype/services/storage_service.dart';

class FakeApiService implements ApiService {
  PricingCorridor? lastPublishedPricing;
  int draftSyncCalls = 0;
  int updateSyncCalls = 0;

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
  Future<String> transcribeAudio(
    String audioPath, {
    String sourceLanguage = 'hi',
  }) async {
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
    lastPublishedPricing = pricing;
    return {'status': 'PUBLISHED', 'catalog_id': item.id};
  }

  @override
  Future<Map<String, dynamic>> saveDraftToBackend(CatalogItem item) async {
    draftSyncCalls++;
    return {'status': 'DRAFT', 'catalog_id': item.id};
  }

  @override
  Future<Map<String, dynamic>> updateListingOnBackend(CatalogItem item) async {
    updateSyncCalls++;
    return {'status': 'PUBLISHED', 'catalog_id': item.id};
  }

  @override
  Future<bool> unlistFromOndc(String catalogId) async => true;

  @override
  Future<bool> deleteFromOndc(String catalogId) async => true;

  @override
  Future<List<CatalogItem>> fetchPublishedListings() async => [];

  @override
  Future<String?> uploadImage(
    String filePath, {
    String imageType = 'studio',
    String? catalogId,
  }) async => 'https://example.com/mock.jpg';

  @override
  Future<ImageUploadResult?> uploadImageWithDetails(
    String filePath, {
    String imageType = 'studio',
    String? catalogId,
  }) async => ImageUploadResult(
    url: 'https://example.com/mock.jpg',
    rawImageUrl: 'https://example.com/mock_raw.jpg',
    studioImageUrl: 'https://example.com/mock_studio.jpg',
    thumbnailUrl: 'https://example.com/mock_thumb.jpg',
    catalogId: catalogId,
  );
}

class FakeAudioService extends AudioService {
  Completer<void>? pendingSpeakCompleter;
  bool stopAllCalled = false;

  @override
  Future<void> speakText(String hindiText) async {
    if (pendingSpeakCompleter != null) {
      await pendingSpeakCompleter!.future;
    }
  }

  @override
  Future<void> stopAllAudio() async {
    stopAllCalled = true;
    if (pendingSpeakCompleter != null && !pendingSpeakCompleter!.isCompleted) {
      pendingSpeakCompleter!.complete();
    }
  }

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
      expect(
        controller.currentItem!.rawImagePath,
        equals('/tmp/artisan_craft.jpg'),
      );
      expect(controller.currentItem!.titleHi, contains('हस्तनिर्मित'));
      expect(
        controller.currentItem!.craftAttributes?.category,
        equals('Pottery'),
      );
      expect(controller.currentItem!.pricing?.fairPrice, greaterThan(0));
    });

    test(
      'processCatalog pipeline executes stages and stores current item',
      () async {
        await controller.processCatalog(
          imagePath: '/tmp/image.jpg',
          audioPath: '/tmp/audio.wav',
        );

        expect(controller.stage, equals(ProcessingStage.done));
        expect(controller.currentItem, isNotNull);
        expect(controller.currentItem!.titleEn, equals('Handmade Silk Shawl'));
      },
    );

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
      expect(controller.currentItem!.pricing?.fairPrice, equals(650));
    });

    test(
      'publishToOndc persists both raw and studio photos to storage',
      () async {
        await controller.createFallbackDraft(
          imagePath: '/tmp/original_craft.jpg',
        );
        expect(
          controller.currentItem!.rawImagePath,
          equals('/tmp/original_craft.jpg'),
        );

        await controller.publishToOndc();
        expect(controller.publishSuccess, isTrue);
        expect(controller.currentItem!.status, equals(CatalogStatus.published));

        final savedCatalogs = await storageService.loadCatalogs();
        expect(savedCatalogs.isNotEmpty, isTrue);
        final lastSaved = savedCatalogs.last;
        expect(lastSaved.rawImagePath, isNotNull);
        expect(lastSaved.studioImagePath, isNotNull);
      },
    );

    test(
      'speakReadback stays isSpeaking=true while playing and stops on stopReadback',
      () async {
        await controller.createFallbackDraft(imagePath: '/tmp/craft.jpg');
        audioService.pendingSpeakCompleter = Completer<void>();

        final speakFuture = controller.speakReadback();
        await Future<void>.delayed(Duration.zero);

        expect(controller.isSpeaking, isTrue);

        await controller.stopReadback();
        await speakFuture;

        expect(audioService.stopAllCalled, isTrue);
        expect(controller.isSpeaking, isFalse);
      },
    );

    test(
      'updating price persists to savedCatalogs, storage, and publishToOndc',
      () async {
        await controller.createFallbackDraft(imagePath: '/tmp/craft.jpg');
        final item = controller.currentItem!;
        final updatedPricing = item.pricing!.copyWith(
          fairPrice: 999,
          sellerProposedPrice: 999,
        );
        await controller.updateCurrentItem(item.copyWith(pricing: updatedPricing));

        expect(controller.currentItem!.pricing!.fairPrice, equals(999));
        expect(
          controller.savedCatalogs.firstWhere((c) => c.id == item.id).pricing!.fairPrice,
          equals(999),
        );
        final saved = await storageService.loadCatalogs();
        expect(saved.last.pricing!.fairPrice, equals(999));

        await controller.publishToOndc();
        expect(apiService.lastPublishedPricing?.fairPrice, equals(999));
      },
    );

    test(
      'syncs draft and published updates to backend and keeps raw/studio separated',
      () async {
        await controller.createFallbackDraft(imagePath: '/tmp/raw_craft.jpg');
        expect(apiService.draftSyncCalls, greaterThanOrEqualTo(1));

        await controller.publishToOndc();
        final beforeUpdate = apiService.updateSyncCalls;
        await controller.updateCurrentItem(
          controller.currentItem!.copyWith(titleEn: 'Updated Brass Lamp'),
        );
        expect(apiService.updateSyncCalls, equals(beforeUpdate + 1));

        final restored = CatalogItem.fromBppListing({
          'catalog_id': 'c_1',
          'title_en': 'Lamp',
          'description_en': 'Desc',
          'floor_price': 100,
          'fair_price': 200,
          'premium_price': 250,
          'raw_image_url': 'https://example.com/raw-craft-images/c_1_raw.jpg',
          'studio_image_url': '',
          'status': 'DRAFT',
        });
        expect(restored.status, equals(CatalogStatus.draft));
        expect(restored.rawImagePath, contains('raw-craft-images'));
        expect(restored.studioImagePath, isNull);
      },
    );
  });
}
