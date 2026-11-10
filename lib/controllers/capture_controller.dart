import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/image_service.dart';

enum CaptureState { idle, previewing, confirmed }

class CaptureController extends ChangeNotifier {
  final ImageService _imageService;

  CaptureController({required this._imageService});

  CaptureState _state = CaptureState.idle;
  bool _isQualityWarningBlur = false;
  bool _isQualityWarningLight = false;
  bool _isBusy = false;

  // Open-ended photo list (no artificial limit)
  final List<String> _capturedPhotos = [];

  // Viewfinder controls
  bool _flashOn = false;
  bool _showGrid = true;
  String _detectedObject = '';
  String _detectedCategory = 'fallback'; // 'pottery' | 'apparel' | 'wood_metal' | 'food' | 'fallback'
  String _detectedStatusLabel = 'अच्छी रोशनी में फोटो लें';

  CaptureState get state => _state;
  List<String> get capturedPhotos => List.unmodifiable(_capturedPhotos);
  String? get primaryPhoto => _capturedPhotos.isNotEmpty ? _capturedPhotos.first : null;
  String? get capturedImagePath => primaryPhoto;
  int get photosCount => _capturedPhotos.length;
  int get photosTakenCount => _capturedPhotos.length;
  bool get canProceed => _capturedPhotos.isNotEmpty;

  // Compatibility mapping for existing integrations
  Map<int, String> get capturedAngles =>
      {for (int i = 0; i < _capturedPhotos.length; i++) i: _capturedPhotos[i]};
  int get activeAngleIndex => _capturedPhotos.length;

  bool get flashOn => _flashOn;
  bool get showGrid => _showGrid;
  bool get isQualityWarningBlur => _isQualityWarningBlur;
  bool get isQualityWarningLight => _isQualityWarningLight;
  bool get isBusy => _isBusy;
  bool get isCameraReady => _imageService.isInitialized;
  CameraController? get cameraController => _imageService.controller;

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
    // Open-ended: selecting slot has no rigid boundary
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void retakeAngle(int index) {
    removePhotoAt(index);
  }

  void removePhotoAt(int index) {
    if (index >= 0 && index < _capturedPhotos.length) {
      _capturedPhotos.removeAt(index);
      _clearWarnings();
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void removePhoto(String path) {
    if (_capturedPhotos.remove(path)) {
      _clearWarnings();
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void clearPhotos() {
    _capturedPhotos.clear();
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
    if (_capturedPhotos.isNotEmpty) {
      _state = CaptureState.confirmed;
      HapticFeedback.lightImpact();
      notifyListeners();
    }
  }

  void retake() {
    _state = CaptureState.idle;
    _capturedPhotos.clear();
    _clearWarnings();
    notifyListeners();
  }

  Future<void> _handleImagePath(String path) async {
    final quality = await _imageService.checkQuality(path);
    _isQualityWarningBlur = quality.isBlurry;
    _isQualityWarningLight = quality.isLowLight;

    _capturedPhotos.add(path);
    _state = CaptureState.idle; // keep viewfinder active so seller can snap more photos
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
