import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';

enum CaptureState { idle, previewing, confirmed }

class CaptureController extends ChangeNotifier {
  final ImageService _imageService;

  CaptureController({required this._imageService});

  CaptureState _state = CaptureState.idle;
  String? _capturedImagePath;
  bool _isQualityWarningBlur = false;
  bool _isQualityWarningLight = false;
  bool _isBusy = false;

  // Multi-angle photo tracker (Front=0, Side=1, Back=2, Detail=3)
  final Map<int, String> _capturedAngles = {};
  int _activeAngleIndex = 0;

  // Viewfinder controls
  bool _flashOn = false;
  bool _showGrid = true;
  String _detectedObject = '';
  String _detectedCategory = 'fallback'; // 'pottery' | 'apparel' | 'wood_metal' | 'food' | 'fallback'
  String _detectedStatusLabel = 'अच्छी रोशनी में फोटो लें';

  CaptureState get state => _state;
  String? get capturedImagePath => _capturedImagePath ?? (_capturedAngles.isNotEmpty ? _capturedAngles.values.first : null);
  bool get isQualityWarningBlur => _isQualityWarningBlur;
  bool get isQualityWarningLight => _isQualityWarningLight;
  bool get isBusy => _isBusy;
  bool get isCameraReady => _imageService.isInitialized;
  CameraController? get cameraController => _imageService.controller;

  Map<int, String> get capturedAngles => _capturedAngles;
  int get activeAngleIndex => _activeAngleIndex;
  int get photosTakenCount => _capturedAngles.length;
  bool get canProceed => _capturedAngles.isNotEmpty || _capturedImagePath != null;

  bool get flashOn => _flashOn;
  bool get showGrid => _showGrid;
  String get detectedObject => _detectedObject;
  String get detectedCategory => _detectedCategory;
  String get detectedStatusLabel => _detectedStatusLabel;
  bool get hasDetectedObject => _detectedObject.isNotEmpty && _detectedCategory != 'fallback';

  Future<void> initCamera() async {
    await _imageService.initCamera();
    notifyListeners();
  }

  Future<void> toggleFlash() async {
    _flashOn = !_flashOn;
    HapticFeedback.selectionClick();
    notifyListeners();
    await _imageService.setFlashMode(_flashOn);
  }

  void toggleGrid() {
    _showGrid = !_showGrid;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void selectAngleSlot(int index) {
    if (index >= 0 && index < 4) {
      _activeAngleIndex = index;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void retakeAngle(int index) {
    _capturedAngles.remove(index);
    _activeAngleIndex = index;
    _capturedImagePath = _capturedAngles.isNotEmpty ? _capturedAngles.values.first : null;
    _state = CaptureState.idle;
    _clearWarnings();
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void setDetectedCategory(String category, {String? objectName, String? statusLabel}) {
    _detectedCategory = category;
    if (objectName != null) _detectedObject = objectName;
    if (statusLabel != null) _detectedStatusLabel = statusLabel;
    notifyListeners();
  }

  Future<void> capturePhoto() async {
    if (_isBusy) return;
    _isBusy = true;
    _clearWarnings();
    notifyListeners();

    HapticFeedback.mediumImpact();

    final path = await _imageService.capturePhoto();
    if (path != null) {
      await _handleImagePath(path);
    }

    _isBusy = false;
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    if (_isBusy) return;
    _isBusy = true;
    _clearWarnings();
    notifyListeners();

    final path = await _imageService.pickFromGallery();
    if (path != null) {
      await _handleImagePath(path);
    }

    _isBusy = false;
    notifyListeners();
  }

  void confirmImage() {
    if (_capturedImagePath != null) {
      _state = CaptureState.confirmed;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }

  void retake() {
    _state = CaptureState.idle;
    _capturedImagePath = null;
    _clearWarnings();
    notifyListeners();
  }

  Future<void> _handleImagePath(String path) async {
    final quality = await _imageService.checkQuality(path);
    _isQualityWarningBlur = quality.isBlurry;
    _isQualityWarningLight = quality.isLowLight;

    _capturedImagePath = path;
    _capturedAngles[_activeAngleIndex] = path;

    // Advance to next uncaptured angle slot if available
    for (int i = 0; i < 4; i++) {
      if (!_capturedAngles.containsKey(i)) {
        _activeAngleIndex = i;
        break;
      }
    }

    _state = CaptureState.idle; // keep viewfinder active so seller can capture more angles
  }

  void _clearWarnings() {
    _isQualityWarningBlur = false;
    _isQualityWarningLight = false;
  }

  @override
  void dispose() {
    _imageService.dispose();
    super.dispose();
  }
}
