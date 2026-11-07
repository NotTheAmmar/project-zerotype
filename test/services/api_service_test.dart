import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/models/catalog_item.dart';
import 'package:project_zerotype/models/pricing_corridor.dart';
import 'package:project_zerotype/services/api_service.dart';

void main() {
  group('ApiService Tests', () {
    test('MockApiService processCatalog runs stages and returns populated result', () async {
      final service = MockApiService();
      final stagesCompleted = <int>[];

      final result = await service.processCatalog(
        imagePath: '/tmp/test_image.jpg',
        audioPath: '/tmp/test_audio.wav',
        onStageComplete: (stage) => stagesCompleted.add(stage),
      );

      expect(stagesCompleted, containsAllInOrder([0, 1, 2]));
      expect(result.titleEn, isNotEmpty);
      expect(result.titleHi, isNotEmpty);
      expect(result.descriptionEn, isNotEmpty);
      expect(result.pricing, isNotNull);
      expect(result.craftAttributes, isNotNull);
    });

    test('MockApiService publishToOndc returns PUBLISHED response', () async {
      final service = MockApiService();
      final corridor = PricingCorridor.compute(
        rawMaterialCost: 150,
        laborDays: 2,
      );

      final response = await service.publishToOndc(
        item: CatalogItem(
          id: 'item_test_001',
          titleEn: 'Handmade Terracotta Diya',
          titleHi: 'हस्तनिर्मित मिट्टी का दीया',
          createdAt: DateTime(2026, 11, 2),
        ),
        pricing: corridor,
        availableQuantity: 10,
      );

      expect(response['status'], equals('PUBLISHED'));
      expect(response['catalog_id'], equals('item_test_001'));
    });

    test('LiveApiService.parseInt handles various data types', () {
      expect(LiveApiService.parseInt(null), isNull);
      expect(LiveApiService.parseInt(42), equals(42));
      expect(LiveApiService.parseInt(99.6), equals(100));
      expect(LiveApiService.parseInt('250'), equals(250));
      expect(LiveApiService.parseInt('invalid_number'), isNull);
    });

    test('LiveApiService.resultFromQwenExtraction parses structured Qwen JSON correctly', () {
      final qwenJson = {
        'commodity_name': 'Diya',
        'craft_type': 'Terracotta Pottery',
        'material': 'Mitti, Red Clay',
        'work_type': 'Hand-thrown on potter wheel',
        'net_quantity': '4 pieces',
        'cluster_location': 'Khurja Pottery Cluster, UP',
        'pricing_inputs': {
          'raw_material_cost': 120,
          'labor_days': 2,
        },
        'spoken_price': 400,
        'spoken_quantity': 4,
        'dimensions': '5 x 5 inches',
        'weight': '250g',
        'title_en': 'Traditional Terracotta Clay Diya Set',
        'title_hi': 'पारंपरिक मिट्टी का दीया सेट',
        'description_en': 'Artisanal clay lamps made from fine natural terracotta.',
        'description_hi': 'शुद्ध प्राकृतिक मिट्टी से निर्मित पारंपरिक दीये।',
      };

      final result = LiveApiService.resultFromQwenExtraction(
        qwenJson,
        descHiFallback: 'माटी के दीये',
      );

      expect(result.titleEn, equals('Traditional Terracotta Clay Diya Set'));
      expect(result.titleHi, equals('पारंपरिक मिट्टी का दीया सेट'));
      expect(result.spokenPrice, equals(400));
      expect(result.spokenQuantity, equals(4));

      final craft = result.craftAttributes;
      expect(craft, isNotNull);
      expect(craft!.category, equals('Terracotta Pottery'));
      expect(craft.materials, containsAll(['Mitti', 'Red Clay']));
      expect(craft.laborDays, equals(2));
      expect(craft.clusterLocation, equals('Khurja Pottery Cluster, UP'));
      expect(craft.dimensions, equals('5 x 5 inches'));
      expect(craft.weight, equals('250g'));

      final pricing = result.pricing;
      expect(pricing, isNotNull);
      expect(pricing!.rawMaterialCost, equals(120));
      expect(pricing.laborDays, equals(2));
      expect(pricing.floorPrice, greaterThan(0));
    });

    test('LiveApiService.resultFromQwenExtraction applies statutory fallbacks when keys are missing', () {
      final minimalJson = <String, dynamic>{
        'commodity_name': 'Shawl',
      };

      final result = LiveApiService.resultFromQwenExtraction(
        minimalJson,
        descHiFallback: 'हाथ से बुनी पश्मीना शॉल',
      );

      expect(result.titleEn, equals('Handmade Shawl'));
      expect(result.titleHi, equals('हस्तनिर्मित उत्पाद'));
      expect(result.descriptionHi, equals('हाथ से बुनी पश्मीना शॉल'));
      expect(result.craftAttributes?.materials, contains('Natural Clay & Earth'));
      expect(result.craftAttributes?.countryOfOrigin, equals('IND'));
      expect(result.pricing, isNotNull);
    });
  });
}
