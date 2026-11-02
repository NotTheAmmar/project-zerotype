import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/models/catalog_item.dart';
import 'package:project_zerotype/models/craft_attributes.dart';
import 'package:project_zerotype/models/pricing_corridor.dart';

void main() {
  group('CatalogItem Model Tests', () {
    test('instantiates with proper default values', () {
      final item = CatalogItem(
        id: 'test_item_001',
        createdAt: DateTime(2026, 11, 2),
        titleEn: 'Terracotta Handcrafted Diya',
        titleHi: 'मिट्टी का हस्तनिर्मित दीया',
      );

      expect(item.id, equals('test_item_001'));
      expect(item.status, equals(CatalogStatus.draft));
      expect(item.availableQuantity, equals(1));
      expect(item.titleEn, equals('Terracotta Handcrafted Diya'));
      expect(item.titleHi, equals('मिट्टी का हस्तनिर्मित दीया'));
    });

    test('copyWith updates state immutably', () {
      final item = CatalogItem(
        id: 'test_item_002',
        createdAt: DateTime.now(),
        availableQuantity: 1,
        status: CatalogStatus.draft,
      );

      final updated = item.copyWith(
        availableQuantity: 5,
        status: CatalogStatus.published,
      );

      expect(updated.availableQuantity, equals(5));
      expect(updated.status, equals(CatalogStatus.published));
      expect(item.availableQuantity, equals(1)); // Original unaltered
    });

    test('JSON serialization round-trip retains craft and pricing attributes', () {
      final corridor = PricingCorridor.compute(
        rawMaterialCost: 150,
        laborDays: 1,
        itemsProduced: 1,
      );

      final attributes = CraftAttributes(
        category: 'pottery',
        materials: ['Clay', 'Terracotta'],
        clusterLocation: 'Pune, Maharashtra',
        artisanName: 'Santosh Kumbhar',
      );

      final item = CatalogItem(
        id: 'cat_round_trip',
        createdAt: DateTime(2026, 11, 2),
        titleEn: 'Clay Diya',
        titleHi: 'मिट्टी का दीया',
        pricing: corridor,
        craftAttributes: attributes,
        availableQuantity: 10,
        status: CatalogStatus.storedLocally,
      );

      final json = item.toJson();
      final restored = CatalogItem.fromJson(json);

      expect(restored.id, equals(item.id));
      expect(restored.titleEn, equals('Clay Diya'));
      expect(restored.craftAttributes?.category, equals('pottery'));
      expect(restored.craftAttributes?.materials, contains('Terracotta'));
      expect(restored.pricing?.floorPrice, equals(corridor.floorPrice));
      expect(restored.availableQuantity, equals(10));
      expect(restored.status, equals(CatalogStatus.storedLocally));
    });
  });
}
