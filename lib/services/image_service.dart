import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../config/constants.dart';
import 'api_service.dart';

class ImageQualityResult {
  final bool isBlurry;
  final bool isLowLight;

  const ImageQualityResult({
    required this.isBlurry,
    required this.isLowLight,
  });

  bool get isAcceptable => !isBlurry && !isLowLight;
}

class ImageService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _cameraController;

  /// Initialize the camera (front camera for selfie, back for product shots)
  Future<void> initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Use back camera for product photography
    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _isInitialized = true;
  }

  Future<void> dispose() async {
    try {
      await _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}
    await _cameraController?.dispose();
    _cameraController = null;
    _isInitialized = false;
  }

  /// Toggle hardware flash mode (torch for illumination, fallback to always/off).
  Future<void> setFlashMode(bool enable) async {
    if (_cameraController == null || !_isInitialized) return;
    try {
      if (enable) {
        try {
          await _cameraController!.setFlashMode(FlashMode.torch);
        } catch (_) {
          await _cameraController!.setFlashMode(FlashMode.always);
        }
      } else {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      debugPrint('[ImageService] setFlashMode error: $e');
    }
  }

  /// Capture a photo from the live viewfinder
  Future<String?> capturePhoto() async {
    if (_cameraController == null || !_isInitialized) return null;
    try {
      final xFile = await _cameraController!.takePicture();
      return xFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Pick an image from the gallery
  Future<String?> pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return xFile?.path;
  }

  /// Quick quality check: blur + low-light detection (runs in a background isolate)
  Future<ImageQualityResult> checkQuality(String imagePath) async {
    if (kIsWeb) {
      // Avoid dart:io File read in isolates on web (which throws Unsupported operation: _Namespace)
      return const ImageQualityResult(isBlurry: false, isLowLight: false);
    }
    try {
      return await compute(_checkQualityIsolate, imagePath);
    } catch (_) {
      return const ImageQualityResult(isBlurry: false, isLowLight: false);
    }
  }

  /// ── Integration point for teammate's BiRefNet model ──
  /// Sends image to Kaggle Dual-T4 BiRefNet-HR pipeline and returns studio URL.
  Future<String?> createStudioImage(String rawImagePath) async {
    try {
      final api = ApiService();
      final url = await api.uploadImage(rawImagePath, imageType: 'studio');
      if (url != null && url.isNotEmpty) {
        return url;
      }
    } catch (e) {
      debugPrint('[ImageService] BiRefNet studio upload failed: $e');
    }
    return null;
  }

}

// ── Top-level function required by compute() — isolates cannot use closures ──
ImageQualityResult _checkQualityIsolate(String imagePath) {
  try {
    final bytes = File(imagePath).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const ImageQualityResult(isBlurry: false, isLowLight: false);
    }

    final gray = img.grayscale(decoded);

    // Blur: Laplacian variance — low variance = blurry
    double sum = 0, sumSq = 0;
    int count = 0;
    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final c = gray.getPixel(x, y).r.toDouble();
        final t = gray.getPixel(x, y - 1).r.toDouble();
        final b = gray.getPixel(x, y + 1).r.toDouble();
        final l = gray.getPixel(x - 1, y).r.toDouble();
        final r = gray.getPixel(x + 1, y).r.toDouble();
        final lap = (4 * c - t - b - l - r).abs();
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }
    final variance = count > 0
        ? (sumSq / count) - (sum / count) * (sum / count)
        : 0.0;
    final isBlurry = variance < AppConstants.blurVarianceThreshold;

    // Low-light: average luminance
    double total = 0;
    final pixelCount = gray.width * gray.height;
    for (final pixel in gray) {
      total += pixel.r.toDouble();
    }
    final avgLuminance = pixelCount > 0 ? total / pixelCount : 0.0;
    final isLowLight = avgLuminance < AppConstants.lowLightLuminanceThreshold;

    return ImageQualityResult(isBlurry: isBlurry, isLowLight: isLowLight);
  } catch (_) {
    return const ImageQualityResult(isBlurry: false, isLowLight: false);
  }
}
