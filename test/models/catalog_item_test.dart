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
        galleryImages: const ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
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
      expect(restored.galleryImages, equals(['https://example.com/img1.jpg', 'https://example.com/img2.jpg']));
      expect(restored.availableQuantity, equals(10));
      expect(restored.status, equals(CatalogStatus.storedLocally));
    });

    test('fromBppListing parses gallery_images and purges dummy saree fallback', () {
      final bppPayload = {
        'catalog_id': 'bpp_item_123',
        'title_en': 'Handloom Shawl',
        'raw_image_url': 'https://storage.supabase.co/raw.jpg',
        'studio_image_url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c',
        'gallery_images': [
          'https://storage.supabase.co/gallery_0.jpg',
          'https://storage.supabase.co/gallery_1.jpg',
        ],
        'available_qty': 3,
        'materials': ['Wool', 'Silk'],
        'cluster_name': 'Kashmir',
        'artisan_name': 'Ghulam',
      };

      final parsed = CatalogItem.fromBppListing(bppPayload);
      expect(parsed.id, equals('bpp_item_123'));
      // Dummy saree photo must be purged and replaced with raw_image_url
      expect(parsed.studioImagePath, equals('https://storage.supabase.co/raw.jpg'));
      expect(parsed.galleryImages, equals([
        'https://storage.supabase.co/gallery_0.jpg',
        'https://storage.supabase.co/gallery_1.jpg',
      ]));
    });
  });
}
