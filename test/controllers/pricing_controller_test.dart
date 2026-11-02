import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/controllers/pricing_controller.dart';

void main() {
  group('PricingController Tests', () {
    test('Initializes with default zero costs and computes base corridor', () {
      final controller = PricingController();

      expect(controller.rawMaterialCost, equals(0));
      expect(controller.laborDays, equals(0));
      expect(controller.availableQuantity, equals(1));
      expect(controller.hasFinalPriceOverride, isFalse);
      expect(controller.finalPrice, equals(controller.corridor.fairPrice));
    });

    test('Initializes with custom values and computes accurate floor, fair, and premium price', () {
      final controller = PricingController(
        initialRawMaterialCost: 200,
        initialLaborDays: 3,
        initialItemsProduced: 1,
        dailyWageRate: 475,
        skillMultiplier: 1.2,
      );

      // Floor: baseCost * 1.10 = (200 + 3 * 475 * 1.2) * 1.10 = (200 + 1710) * 1.10 = 1910 * 1.10 = 2101
      expect(controller.corridor.floorPrice, equals(2101));
      expect(controller.corridor.fairPrice, greaterThan(controller.corridor.floorPrice));
      expect(controller.corridor.premiumPrice, greaterThan(controller.corridor.fairPrice));
    });

    test('Modifying raw material cost recalculates corridor', () {
      final controller = PricingController(
        initialRawMaterialCost: 100,
        initialLaborDays: 1,
      );
      final initialFloor = controller.corridor.floorPrice;

      controller.setRawMaterialCost(300);
      expect(controller.rawMaterialCost, equals(300));
      expect(controller.corridor.floorPrice, greaterThan(initialFloor));

      controller.incrementRawMaterial(step: 50);
      expect(controller.rawMaterialCost, equals(350));

      controller.decrementRawMaterial(step: 100);
      expect(controller.rawMaterialCost, equals(250));
    });

    test('Modifying labor days updates corridor', () {
      final controller = PricingController(
        initialRawMaterialCost: 100,
        initialLaborDays: 1,
        dailyWageRate: 475,
      );
      final floor1Day = controller.corridor.floorPrice;

      controller.incrementLaborDays();
      expect(controller.laborDays, equals(2));
      expect(controller.corridor.floorPrice, greaterThan(floor1Day));

      controller.decrementLaborDays();
      expect(controller.laborDays, equals(1));
      expect(controller.corridor.floorPrice, equals(floor1Day));
    });

    test('Inventory quantity controls work within clamp bounds', () {
      final controller = PricingController(initialQuantity: 5);
      expect(controller.availableQuantity, equals(5));

      controller.incrementQuantity(step: 3);
      expect(controller.availableQuantity, equals(8));

      controller.decrementQuantity(step: 2);
      expect(controller.availableQuantity, equals(6));

      // Cannot be less than 1
      controller.setAvailableQuantity(0);
      expect(controller.availableQuantity, equals(1));
    });

    test('Manual price override validates statutory floor', () {
      final controller = PricingController(
        initialRawMaterialCost: 200,
        initialLaborDays: 2,
        dailyWageRate: 475,
      );
      final floorPrice = controller.corridor.floorPrice;

      // Price below floor must return validation error
      final belowFloorError = controller.setFinalPrice(floorPrice - 50);
      expect(belowFloorError, isNotNull);
      expect(belowFloorError, contains('कम'));
      expect(controller.hasFinalPriceOverride, isFalse);

      // Price at or above floor should succeed
      final validOverride = controller.setFinalPrice(floorPrice + 500);
      expect(validOverride, isNull);
      expect(controller.hasFinalPriceOverride, isTrue);
      expect(controller.finalPrice, equals(floorPrice + 500));

      // Clearing manual override resets to computed fair price
      controller.clearFinalPriceOverride();
      expect(controller.hasFinalPriceOverride, isFalse);
      expect(controller.finalPrice, equals(controller.corridor.fairPrice));
    });

    test('seedFromExtracted updates all core parameters simultaneously', () {
      final controller = PricingController();
      controller.seedFromExtracted(
        rawMaterialCost: 350,
        laborDays: 4,
        itemsProduced: 2,
        sellerProposedPrice: 2000,
      );

      expect(controller.rawMaterialCost, equals(350));
      expect(controller.laborDays, equals(4));
      expect(controller.itemsProduced, equals(2));
      expect(controller.sellerProposedPrice, equals(2000));
      expect(controller.corridor.floorPrice, greaterThan(0));
    });
  });
}
