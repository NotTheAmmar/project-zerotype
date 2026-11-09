import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/models/pricing_corridor.dart';

void main() {
  group('PricingCorridor Model Tests', () {
    test('computes statutory floor price correctly for single item', () {
      // 1 day labor, ₹500/day, ₹100 raw materials, 10% overhead
      // Base labor: 1 * 500 * 1.0 = 500
      // Base cost: 100 + 500 = 600
      // Overhead: 600 * 0.10 = 60
      // Floor: 600 + 60 = 660
      final corridor = PricingCorridor.compute(
        rawMaterialCost: 100,
        laborDays: 1,
        dailyWageRate: 500,
        skillMultiplier: 1.0,
        overheadPercent: 0.10,
        itemsProduced: 1,
      );

      expect(corridor.floorPrice, equals(660));
      expect(corridor.fairPrice, greaterThanOrEqualTo(corridor.floorPrice));
      expect(corridor.premiumPrice, greaterThanOrEqualTo(corridor.fairPrice));
    });

    test('scales floor price per item when batch itemsProduced > 1', () {
      final corridor = PricingCorridor.compute(
        rawMaterialCost: 200,
        laborDays: 2,
        dailyWageRate: 500,
        itemsProduced: 4,
      );

      // Base labor: 2 * 500 = 1000
      // Base cost: 200 + 1000 = 1200
      // Overhead 10%: 120
      // Total: 1320 / 4 items = 330
      expect(corridor.floorPrice, equals(330));
    });

    test('applies skillMultiplier for master artisans', () {
      final basic = PricingCorridor.compute(
        rawMaterialCost: 100,
        laborDays: 2,
        dailyWageRate: 500,
        skillMultiplier: 1.0,
      );

      final master = PricingCorridor.compute(
        rawMaterialCost: 100,
        laborDays: 2,
        dailyWageRate: 500,
        skillMultiplier: 1.5,
      );

      expect(master.floorPrice, greaterThan(basic.floorPrice));
    });

    test('serializes and deserializes to/from JSON accurately', () {
      final original = PricingCorridor.compute(
        rawMaterialCost: 300,
        laborDays: 3,
        itemsProduced: 2,
        sellerProposedPrice: 850,
      );

      final json = original.toJson();
      final recreated = PricingCorridor.fromJson(json);

      expect(recreated.floorPrice, equals(original.floorPrice));
      expect(recreated.fairPrice, equals(original.fairPrice));
      expect(recreated.premiumPrice, equals(original.premiumPrice));
      expect(recreated.sellerProposedPrice, equals(850));
    });

    test('respects seller proposed price when provided', () {
      final corridor = PricingCorridor.compute(
        rawMaterialCost: 100,
        laborDays: 1,
        dailyWageRate: 500,
        sellerProposedPrice: 100,
      );

      expect(corridor.fairPrice, equals(100));
      expect(corridor.floorPrice, lessThanOrEqualTo(100));
      expect(corridor.premiumPrice, equals(120));
      expect(corridor.sellerProposedPrice, equals(100));
    });
  });
}
