import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/catalog_item.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/bhashini_service.dart';
import '../services/storage_service.dart';
import 'pricing_controller.dart';

enum ProcessingStage { notStarted, imageProcessing, voiceProcessing, pricing, done, error }

class CatalogController extends ChangeNotifier {
  final ApiService _apiService;
  final AudioService _audioService;
  final StorageService _storageService;

  CatalogController({
    required this._apiService,
    required this._audioService,
    required this._storageService,
  }) {
    loadSavedCatalogs();
  }

  ProcessingStage _stage = ProcessingStage.notStarted;
  CatalogItem? _currentItem;
  List<CatalogItem> _savedCatalogs = [];
  bool _isLoadingCatalogs = false;
  bool _showStudioImage = false;
  bool _isSpeaking = false;
  bool _isPublishing = false;
  bool _publishSuccess = false;
  String? _errorMessage;

  ProcessingStage get stage => _stage;
  CatalogItem? get currentItem => _currentItem;
  CatalogItem? get item => _currentItem;
  List<CatalogItem> get savedCatalogs => _savedCatalogs;
  bool get isLoadingCatalogs => _isLoadingCatalogs;
  bool get showStudioImage => _showStudioImage;
  bool get isSpeaking => _isSpeaking;
  bool get isPublishing => _isPublishing;
  bool get publishSuccess => _publishSuccess;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedCatalogs() async {
    _isLoadingCatalogs = true;
    notifyListeners();
    try {
      // 1. Fast local load for immediate UI rendering
      final localCatalogs = await _storageService.loadCatalogs();
      _savedCatalogs = List.from(localCatalogs);
      notifyListeners();

      // 2. Remote sync: fetch active listings persisted in the backend database
      final remoteListings = await _apiService.fetchPublishedListings();
      if (remoteListings.isNotEmpty) {
        for (final remote in remoteListings) {
          final idx = _savedCatalogs.indexWhere((c) => c.id == remote.id);
          if (idx >= 0) {
            _savedCatalogs[idx] = remote;
          } else {
            _savedCatalogs.insert(0, remote);
          }
          await _storageService.saveCatalog(remote);
        }
      }
    } catch (e) {
      debugPrint('[CatalogController] Error loading catalogs: $e');
    } finally {
      _isLoadingCatalogs = false;
      notifyListeners();
    }
  }

  void setItem(CatalogItem item) {
    _currentItem = item;
    _stage = ProcessingStage.done;
    notifyListeners();
  }

  /// Main pipeline: takes captured image + recorded audio → produces CatalogItem
  Future<void> processCatalog({
    required String imagePath,
    required String audioPath,
    List<String>? audioPaths,
    String? manualDimensions,
  }) async {
    _stage = ProcessingStage.imageProcessing;
    _errorMessage = null;
    _publishSuccess = false;
    notifyListeners();

    try {
      final result = await _apiService.processCatalog(
        imagePath: imagePath,
        audioPath: audioPath,
        audioPaths: audioPaths,
        manualDimensions: manualDimensions,
        onStageComplete: (stage) {
          switch (stage) {
            case 0:
              _stage = ProcessingStage.imageProcessing;
            case 1:
              _stage = ProcessingStage.voiceProcessing;
            case 2:
              _stage = ProcessingStage.pricing;
          }
          notifyListeners();
        },
      );

      _currentItem = CatalogItem(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        rawImagePath: imagePath,
        studioImagePath: result.studioImagePath,
        audioPath: audioPath,
        titleEn: result.titleEn,
        titleHi: result.titleHi,
        descriptionEn: result.descriptionEn,
        descriptionHi: result.descriptionHi,
        craftAttributes: result.craftAttributes,
        pricing: result.pricing,
        availableQuantity: result.spokenQuantity ?? 1,
        status: CatalogStatus.draft,
      );

      // Warm the image cache now so the studio photo is ready by the time
      // the user reaches the catalog screen (avoids visible load flash).
      if (result.studioImagePath != null &&
          result.studioImagePath!.startsWith('http')) {
        _precacheStudioImage(result.studioImagePath!);
      }

      // Persist locally
      await _storageService.saveCatalog(_currentItem!);
      _updateSavedList(_currentItem!);

      _stage = ProcessingStage.done;
      notifyListeners();
    } catch (e) {
      _stage = ProcessingStage.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Creates a draft catalog directly when network or AI extraction fails,
  /// preserving artisan captured photos & audio so work is never lost.
  Future<void> createFallbackDraft({
    required String imagePath,
    String? audioPath,
    String? category,
  }) async {
    _currentItem = CatalogItem(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      rawImagePath: imagePath,
      studioImagePath: imagePath,
      audioPath: audioPath,
      titleEn: 'Handcrafted Artisan Item',
      titleHi: 'हस्तनिर्मित शिल्प उत्पाद',
      descriptionEn:
          'Authentic handmade craft directly from generational artisan creators.',
      descriptionHi:
          'कुशल कारीगर द्वारा पारंपरिक विधि से हस्तनिर्मित उत्कृष्ट उत्पाद।',
      craftAttributes: CraftAttributes(
        category: (category != null && category != 'fallback')
            ? category
            : 'Handmade Craft',
        materials: ['Natural Artisan Materials'],
        laborDays: 1,
        clusterLocation: 'India Craft Cluster',
        artisanName: 'BazaarSetu Artisan',
        countryOfOrigin: 'IND',
      ),
      pricing: PricingCorridor.compute(
        rawMaterialCost: 100,
        laborDays: 1,
        sellerProposedPrice: 350,
      ),
      availableQuantity: 1,
      status: CatalogStatus.draft,
    );

    await _storageService.saveCatalog(_currentItem!);
    _updateSavedList(_currentItem!);

    _stage = ProcessingStage.done;
    _errorMessage = null;
    notifyListeners();
  }

  /// Updates current item manually (via edit form or manual adjustments).
  Future<void> updateCurrentItem(CatalogItem updated) async {
    _currentItem = updated;
    await _storageService.saveCatalog(_currentItem!);
    _updateSavedList(_currentItem!);
    notifyListeners();
  }

  /// Modifies current item using AI voice command (Whisper + Qwen/Gemini).
  Future<void> applyVoiceUpdate(String instruction) async {
    if (_currentItem == null) return;
    try {
      final updated = await _apiService.updateCatalogWithInstruction(
        currentItem: _currentItem!,
        instruction: instruction,
      );
      await updateCurrentItem(updated);
      await _audioService.speakText('कैटलॉग अपडेट कर दिया गया है।');
    } catch (e) {
      debugPrint('[CatalogController] applyVoiceUpdate error: $e');
      rethrow;
    }
  }

  void togglePhotoView() {
    _showStudioImage = !_showStudioImage;
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  final BhashiniService _bhashiniService = BhashiniService();

  Future<void> speakReadback() async {
    if (_currentItem == null || _isSpeaking) return;
    _isSpeaking = true;
    notifyListeners();

    final descHi = _currentItem!.descriptionHi?.trim() ?? '';
    final descEn = _currentItem!.descriptionEn?.trim() ?? '';
    final textToSpeak = descHi.isNotEmpty
        ? descHi
        : (descEn.isNotEmpty ? descEn : (_currentItem!.titleHi ?? _currentItem!.titleEn ?? ''));

    if (textToSpeak.isNotEmpty) {
      if (AppConstants.bhashiniApiKey.isNotEmpty && descHi.isNotEmpty) {
        try {
          final audioPath = await _bhashiniService.synthesize(
            textToSpeak,
            sourceLanguage: 'hi',
            gender: 'female',
          );
          await _audioService.playFile(audioPath);
          _isSpeaking = false;
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('[BhashiniTTS] failed, falling back to device TTS: $e');
        }
      }

      await _audioService.speakText(textToSpeak);
    }

    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopReadback() async {
    await _audioService.stopAllAudio();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Publish to ONDC via the BPP backend.
  Future<void> publishToOndc([
    PricingController? pricingCtrl,
    int availableQuantity = 1,
  ]) async {
    if (_currentItem == null || _isPublishing) return;
    _isPublishing = true;
    _publishSuccess = false;
    _errorMessage = null;
    notifyListeners();

    final pricing = pricingCtrl?.corridor ?? _currentItem?.pricing;
    final qty = pricingCtrl?.availableQuantity ?? availableQuantity;

    if (pricing == null || pricing.floorPrice <= 0 || pricing.fairPrice <= 0) {
      _errorMessage = 'मूल्य 0 से अधिक होना चाहिए / Price must be greater than ₹0 before publishing';
      _isPublishing = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _apiService.publishToOndc(
        item: _currentItem!,
        pricing: pricing,
        availableQuantity: qty,
      );

      if (response['status'] == 'PUBLISHED') {
        _currentItem = _currentItem!.copyWith(status: CatalogStatus.published);
        await _storageService.saveCatalog(_currentItem!);
        _updateSavedList(_currentItem!);
        _publishSuccess = true;
        HapticFeedback.heavyImpact();

        // TTS confirmation in Hindi
        await _audioService.speakText(
          'आपका उत्पाद ओ.एन.डी.सी. पर प्रकाशित हो गया है।',
        );
      } else {
        _errorMessage = response['message'] ?? 'Publish failed';
      }
    } catch (e) {
      _errorMessage = 'Publish failed: ${e.toString()}';
    }

    _isPublishing = false;
    notifyListeners();
  }

  /// Warms the Flutter image cache for [url] in the background.
  /// Uses [NetworkImage] directly — no BuildContext needed.
  void _precacheStudioImage(String url) {
    final provider = NetworkImage(
      url,
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    provider.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener(
        (info, _) {}, // success — image is now in cache
        onError: (e, _) {}, // ignore cache-warm errors silently
      ),
    );
  }

  void reset() {
    _stage = ProcessingStage.notStarted;
    _currentItem = null;
    _showStudioImage = false;
    _isSpeaking = false;
    _isPublishing = false;
    _publishSuccess = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _updateSavedList(CatalogItem item) {
    final index = _savedCatalogs.indexWhere((c) => c.id == item.id);
    if (index >= 0) {
      _savedCatalogs[index] = item;
    } else {
      _savedCatalogs.insert(0, item);
    }
    notifyListeners();
  }

  Future<void> unpublishCatalog(CatalogItem item) async {
    final draftItem = item.copyWith(status: CatalogStatus.draft);
    _currentItem = draftItem;
    await _storageService.saveCatalog(draftItem);
    _updateSavedList(draftItem);
    _publishSuccess = false;
    notifyListeners();

    try {
      await _apiService.unlistFromOndc(item.id);
    } catch (e) {
      debugPrint('[CatalogController] unlist failed: $e');
    }
  }

  Future<void> deleteCatalog(String id) async {
    await _storageService.deleteCatalog(id);
    _savedCatalogs.removeWhere((item) => item.id == id);
    if (_currentItem?.id == id) {
      _currentItem = null;
    }
    notifyListeners();

    try {
      await _apiService.deleteFromOndc(id);
    } catch (e) {
      debugPrint('[CatalogController] deleteFromOndc failed: $e');
    }
  }

  @override
  void dispose() {
    _audioService.stopTts();
    _bhashiniService.dispose();
    super.dispose();
  }
}
