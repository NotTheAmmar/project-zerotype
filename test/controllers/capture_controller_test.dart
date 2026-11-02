import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/controllers/capture_controller.dart';
import 'package:project_zerotype/services/image_service.dart';

class FakeImageService extends ImageService {
  String? nextPhotoPath = '/tmp/fake_photo.jpg';
  bool isBlurry = false;
  bool isLowLight = false;

  @override
  Future<String?> capturePhoto() async {
    return nextPhotoPath;
  }

  @override
  Future<String?> pickFromGallery() async {
    return '/tmp/gallery_photo.jpg';
  }

  @override
  Future<ImageQualityResult> checkQuality(String path) async {
    return ImageQualityResult(isBlurry: isBlurry, isLowLight: isLowLight);
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CaptureController Tests', () {
    late FakeImageService fakeImageService;
    late CaptureController controller;

    setUp(() {
      fakeImageService = FakeImageService();
      controller = CaptureController(imageService: fakeImageService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state has default settings and no photos', () {
      expect(controller.state, equals(CaptureState.idle));
      expect(controller.capturedImagePath, isNull);
      expect(controller.capturedAngles, isEmpty);
      expect(controller.activeAngleIndex, equals(0));
      expect(controller.photosTakenCount, equals(0));
      expect(controller.canProceed, isFalse);
      expect(controller.flashOn, isFalse);
      expect(controller.showGrid, isTrue);
      expect(controller.isBusy, isFalse);
      expect(controller.isQualityWarningBlur, isFalse);
      expect(controller.isQualityWarningLight, isFalse);
    });

    test('Toggles flash and grid state correctly', () {
      expect(controller.flashOn, isFalse);
      controller.toggleFlash();
      expect(controller.flashOn, isTrue);
      controller.toggleFlash();
      expect(controller.flashOn, isFalse);

      expect(controller.showGrid, isTrue);
      controller.toggleGrid();
      expect(controller.showGrid, isFalse);
      controller.toggleGrid();
      expect(controller.showGrid, isTrue);
    });

    test('Angle slot selection works within valid range 0-3', () {
      controller.selectAngleSlot(2);
      expect(controller.activeAngleIndex, equals(2));

      controller.selectAngleSlot(3);
      expect(controller.activeAngleIndex, equals(3));

      // Out of range should be ignored
      controller.selectAngleSlot(5);
      expect(controller.activeAngleIndex, equals(3));
    });

    test('setDetectedCategory updates category and labels', () {
      controller.setDetectedCategory(
        'apparel',
        objectName: 'Silk Dupatta',
        statusLabel: 'Dupatta detected • Good light',
      );
      expect(controller.detectedCategory, equals('apparel'));
      expect(controller.detectedObject, equals('Silk Dupatta'));
      expect(controller.detectedStatusLabel, equals('Dupatta detected • Good light'));
    });

    test('Capturing photos updates angle slots and advances active slot', () async {
      fakeImageService.nextPhotoPath = '/tmp/angle_0.jpg';
      await controller.capturePhoto();

      expect(controller.photosTakenCount, equals(1));
      expect(controller.capturedAngles[0], equals('/tmp/angle_0.jpg'));
      expect(controller.canProceed, isTrue);
      // Auto-advanced to slot 1
      expect(controller.activeAngleIndex, equals(1));

      // Capture slot 1
      fakeImageService.nextPhotoPath = '/tmp/angle_1.jpg';
      await controller.capturePhoto();
      expect(controller.photosTakenCount, equals(2));
      expect(controller.capturedAngles[1], equals('/tmp/angle_1.jpg'));
      expect(controller.activeAngleIndex, equals(2));
    });

    test('Quality warnings are set when image is blurry or low light', () async {
      fakeImageService.isBlurry = true;
      fakeImageService.isLowLight = true;

      await controller.capturePhoto();
      expect(controller.isQualityWarningBlur, isTrue);
      expect(controller.isQualityWarningLight, isTrue);

      // Retake clears warnings
      controller.retake();
      expect(controller.isQualityWarningBlur, isFalse);
      expect(controller.isQualityWarningLight, isFalse);
    });

    test('retakeAngle removes specific angle slot and resets active index', () async {
      await controller.capturePhoto(); // slot 0
      expect(controller.capturedAngles.containsKey(0), isTrue);

      controller.retakeAngle(0);
      expect(controller.capturedAngles.containsKey(0), isFalse);
      expect(controller.activeAngleIndex, equals(0));
      expect(controller.canProceed, isFalse);
    });

    test('confirmImage changes state to confirmed', () async {
      await controller.capturePhoto();
      expect(controller.state, equals(CaptureState.idle));

      controller.confirmImage();
      expect(controller.state, equals(CaptureState.confirmed));
    });
  });
}
