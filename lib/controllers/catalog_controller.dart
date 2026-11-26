import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/catalog_item.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/bhashini_service.dart';
import '../services/storage_service.dart';
import 'pricing_controller.dart';

enum ProcessingStage {
  notStarted,
  imageProcessing,
  voiceProcessing,
  pricing,
  done,
  error,
}

class CatalogController extends ChangeNotifier {
  final ApiService _apiService;
  final AudioService _audioService;
  final StorageService _storageService;
  final BhashiniService _bhashiniService;

  CatalogController({
    required this._apiService,
    required this._audioService,
    required this._storageService,
    BhashiniService? bhashiniService,
  }) : _bhashiniService = bhashiniService ?? BhashiniService() {
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
  bool _isBackgroundSyncing = false;
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
  bool get isBackgroundSyncing => _isBackgroundSyncing;
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
      final remoteIds = <String>{};
      if (remoteListings.isNotEmpty) {
        for (final remote in remoteListings) {
          remoteIds.add(remote.id);
          final idx = _savedCatalogs.indexWhere((c) => c.id == remote.id);
          if (idx >= 0) {
            final localItem = _savedCatalogs[idx];
            // Preserve local raw/gallery paths if remote doesn't yet have them
            final merged = remote.copyWith(
              rawImagePath: (remote.rawImagePath?.isNotEmpty == true)
                  ? remote.rawImagePath
                  : localItem.rawImagePath,
              studioImagePath: (remote.studioImagePath?.isNotEmpty == true)
                  ? remote.studioImagePath
                  : localItem.studioImagePath,
              galleryImages: remote.galleryImages.isNotEmpty
                  ? remote.galleryImages
                  : localItem.galleryImages,
            );
            _savedCatalogs[idx] = merged;
            await _storageService.saveCatalog(merged);
          } else {
            _savedCatalogs.insert(0, remote);
            await _storageService.saveCatalog(remote);
          }
        }
      }

      // 3. Fire non-blocking offline -> online sync + deferred Kaggle image processing
      unawaited(syncPendingWithBackendAndKaggle(knownRemoteIds: remoteIds));
    } catch (e) {
      debugPrint('[CatalogController] Error loading catalogs: $e');
    } finally {
      _isLoadingCatalogs = false;
      notifyListeners();
    }
  }

  /// Syncs any offline-saved catalogs to Supabase/Render and, whenever the
  /// Kaggle BiRefNet GPU server is reachable, processes any catalog missing
  /// an AI studio photo (or having unprocessed local gallery photos) in the background.
  Future<int> syncPendingWithBackendAndKaggle({
    Set<String>? knownRemoteIds,
  }) async {
    if (_isBackgroundSyncing) return 0;
    _isBackgroundSyncing = true;
    int updatedCount = 0;

    try {
      final kaggleOnline = await _apiService.isKaggleHealthy();
      final snapshot = List<CatalogItem>.from(_savedCatalogs);

      for (final item in snapshot) {
        bool changed = false;
        CatalogItem working = item;

        final hasLocalRaw =
            working.rawImagePath != null &&
            working.rawImagePath!.isNotEmpty &&
            !working.rawImagePath!.startsWith('http');
        final notSyncedRemotely =
            knownRemoteIds != null && !knownRemoteIds.contains(working.id);

        // 1. Ensure draft/published item & raw image are synced to Supabase via Render
        if (hasLocalRaw || notSyncedRemotely) {
          await _syncToBackend(working);
          final refreshed = _savedCatalogs.firstWhere(
            (c) => c.id == working.id,
            orElse: () => working,
          );
          if (refreshed.rawImagePath != working.rawImagePath) {
            working = refreshed;
            changed = true;
          }
        }

        // 2. If Kaggle GPU is online and item lacks a processed studio photo, generate it now
        if (kaggleOnline) {
          final needsStudio =
              (working.studioImagePath == null ||
                  working.studioImagePath!.isEmpty ||
                  working.studioImagePath == working.rawImagePath) &&
              working.rawImagePath != null &&
              working.rawImagePath!.isNotEmpty;

          String? newStudioUrl;
          if (needsStudio) {
            try {
              newStudioUrl = await _apiService.processImageWithKaggle(
                working.rawImagePath!,
                catalogId: working.id,
                imageType: 'studio',
              );
            } catch (e) {
              debugPrint(
                '[CatalogController] Deferred Kaggle studio failed for ${working.id}: $e',
              );
            }
          }

          // Also process any local gallery photos not yet turned into remote URLs
          bool galleryChanged = false;
          final updatedGallery = <String>[];
          for (int i = 0; i < working.galleryImages.length; i++) {
            final g = working.galleryImages[i];
            if (g.startsWith('http://') || g.startsWith('https://')) {
              updatedGallery.add(g);
            } else if (g.isNotEmpty) {
              try {
                final proc = await _apiService.processImageWithKaggle(
                  g,
                  catalogId: working.id,
                  imageType: 'gallery_$i',
                );
                if (proc != null && proc.isNotEmpty) {
                  updatedGallery.add(proc);
                  galleryChanged = true;
                } else {
                  updatedGallery.add(g);
                }
              } catch (_) {
                updatedGallery.add(g);
              }
            }
          }

          if ((newStudioUrl != null && newStudioUrl.isNotEmpty) ||
              galleryChanged) {
            working = working.copyWith(
              studioImagePath:
                  (newStudioUrl != null && newStudioUrl.isNotEmpty)
                  ? newStudioUrl
                  : working.studioImagePath,
              galleryImages: galleryChanged
                  ? updatedGallery
                  : working.galleryImages,
            );
            if (_currentItem?.id == working.id) {
              _currentItem = working;
            }
            await _storageService.saveCatalog(working);
            _updateSavedList(working);
            await _syncToBackend(working);
            if (working.studioImagePath?.startsWith('http') == true) {
              _precacheStudioImage(working.studioImagePath!);
            }
            updatedCount++;
            changed = true;
          }
        }

        if (changed) notifyListeners();
      }
    } catch (e) {
      debugPrint('[CatalogController] Background sync error: $e');
    } finally {
      _isBackgroundSyncing = false;
    }
    return updatedCount;
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
    List<String>? galleryImagePaths,
    String? manualDimensions,
    String voiceLanguage = 'hi',
    String primaryLanguage = 'en',
    String? secondaryLanguage = 'hi',
  }) async {
    _stage = ProcessingStage.imageProcessing;
    _errorMessage = null;
    _publishSuccess = false;
    notifyListeners();

    final catalogId = const Uuid().v4();

    try {
      final result = await _apiService.processCatalog(
        imagePath: imagePath,
        audioPath: audioPath,
        audioPaths: audioPaths,
        manualDimensions: manualDimensions,
        catalogId: catalogId,
        voiceLanguage: voiceLanguage,
        primaryLanguage: primaryLanguage,
        secondaryLanguage: secondaryLanguage,
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
        id: catalogId,
        createdAt: DateTime.now(),
        rawImagePath: result.rawImagePath ?? imagePath,
        studioImagePath: result.studioImagePath,
        audioPath: audioPath,
        galleryImages: galleryImagePaths ?? const [],
        titleEn: result.titleEn,
        titleHi: result.titleHi,
        descriptionEn: result.descriptionEn,
        descriptionHi: result.descriptionHi,
        localizedTitles: result.localizedTitles,
        localizedDescriptions: result.localizedDescriptions,
        craftAttributes: result.craftAttributes,
        pricing: result.pricing,
        availableQuantity: result.spokenQuantity ?? 1,
        status: CatalogStatus.draft,
      );

      // Warm the image cache now so both raw & studio photos are ready by the time
      // the user reaches the catalog screen (avoids visible load flash).
      if (result.studioImagePath != null &&
          result.studioImagePath!.startsWith('http')) {
        _precacheStudioImage(result.studioImagePath!);
      }
      if (result.rawImagePath != null &&
          result.rawImagePath!.startsWith('http')) {
        _precacheStudioImage(result.rawImagePath!);
      }

      // Persist locally and sync draft to backend DB
      await _storageService.saveCatalog(_currentItem!);
      _updateSavedList(_currentItem!);
      await _syncToBackend(_currentItem!);

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
    List<String>? galleryImagePaths,
    String? category,
  }) async {
    final existingStudio = _currentItem?.studioImagePath;
    final finalStudio =
        (existingStudio != null &&
            existingStudio.isNotEmpty &&
            existingStudio != imagePath)
        ? existingStudio
        : imagePath;

    _currentItem = CatalogItem(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      rawImagePath: imagePath,
      studioImagePath: finalStudio,
      audioPath: audioPath,
      galleryImages: galleryImagePaths ?? const [],
      titleEn: 'Handcrafted Artisan Item',
      titleHi: 'हस्तनिर्मित शिल्प उत्पाद',
      descriptionEn: 'Authentic handmade craft directly from generational artisan creators.',
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
    await _syncToBackend(_currentItem!);

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
    await _syncToBackend(_currentItem!);
  }

  Future<void> _syncToBackend(CatalogItem item) async {
    try {
      final Map<String, dynamic> res;
      if (item.status == CatalogStatus.published) {
        res = await _apiService.updateListingOnBackend(item);
      } else {
        res = await _apiService.saveDraftToBackend(item);
      }
      final returnedRaw = res['raw_image_url'] as String?;
      final returnedStudio = res['studio_image_url'] as String?;
      if ((returnedRaw != null &&
              returnedRaw.isNotEmpty &&
              returnedRaw != item.rawImagePath) ||
          (returnedStudio != null &&
              returnedStudio.isNotEmpty &&
              returnedStudio != item.studioImagePath)) {
        final synced = item.copyWith(
          rawImagePath: (returnedRaw != null && returnedRaw.isNotEmpty)
              ? returnedRaw
              : item.rawImagePath,
          studioImagePath: (returnedStudio != null && returnedStudio.isNotEmpty)
              ? returnedStudio
              : item.studioImagePath,
        );
        if (_currentItem?.id == item.id) {
          _currentItem = synced;
        }
        await _storageService.saveCatalog(synced);
        _updateSavedList(synced);
      }
    } catch (e) {
      debugPrint('[CatalogController] Backend sync skipped (offline/local): $e');
    }
  }

  /// Speaks short status confirmations via Bhashini TTS in the selected [languageCode].
  Future<void> _speakConfirmation({
    required String textEn,
    required String textHi,
    required String languageCode,
  }) async {
    try {
      String text;
      if (languageCode == 'en') {
        text = textEn;
      } else if (languageCode == 'hi') {
        text = textHi;
      } else {
        try {
          text = await _bhashiniService.translate(
            textEn,
            sourceLanguage: 'en',
            targetLanguage: languageCode,
          );
        } catch (_) {
          text = textEn;
        }
      }
      if (text.trim().isEmpty) return;
      final audioPath = await _bhashiniService.synthesize(
        text,
        sourceLanguage: languageCode,
        gender: 'female',
      );
      await _audioService.playFile(audioPath);
    } catch (e) {
      debugPrint('[CatalogController] Confirmation TTS skipped ($languageCode): $e');
    }
  }

  /// Modifies current item using AI voice command (Bhashini + Qwen).
  Future<void> applyVoiceUpdate(
    String instruction, {
    String languageCode = 'hi',
  }) async {
    if (_currentItem == null) return;
    try {
      final updated = await _apiService.updateCatalogWithInstruction(
        currentItem: _currentItem!,
        instruction: instruction,
      );
      await updateCurrentItem(updated);
      unawaited(
        _speakConfirmation(
          textEn: 'Your catalog listing has been updated.',
          textHi: 'कैटलॉग अपडेट कर दिया गया है।',
          languageCode: languageCode,
        ),
      );
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

  Future<void> speakReadback({
    String languageCode = 'hi',
    String ttsLocale = 'hi-IN',
  }) async {
    if (_currentItem == null || _isSpeaking) return;
    _isSpeaking = true;
    notifyListeners();

    try {
      final locDesc = _currentItem!.descriptionFor(languageCode)?.trim() ?? '';
      final descHi = _currentItem!.descriptionHi?.trim() ?? '';
      final descEn = _currentItem!.descriptionEn?.trim() ?? '';
      final textToSpeak = locDesc.isNotEmpty
          ? locDesc
          : (descHi.isNotEmpty
                ? descHi
                : (descEn.isNotEmpty
                      ? descEn
                      : (_currentItem!.titleFor(languageCode) ??
                            _currentItem!.titleHi ??
                            _currentItem!.titleEn ??
                            '')));

      if (textToSpeak.isNotEmpty) {
        final ttsLang = locDesc.isNotEmpty
            ? languageCode
            : (descHi.isNotEmpty ? 'hi' : 'en');
        final audioPath = await _bhashiniService.synthesize(
          textToSpeak,
          sourceLanguage: ttsLang,
          gender: 'female',
        );
        if (!_isSpeaking) return;
        await _audioService.playFile(audioPath);
      }
    } catch (e) {
      debugPrint('[BhashiniTTS] failed: $e');
      _errorMessage = 'Bhashini TTS failed: $e';
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
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
    bool silent = false,
    String languageCode = 'hi',
  ]) async {
    if (_currentItem == null || _isPublishing) return;
    _isPublishing = true;
    _publishSuccess = false;
    _errorMessage = null;
    notifyListeners();

    final pricing = pricingCtrl?.corridor ?? _currentItem?.pricing;
    final qty = pricingCtrl?.availableQuantity ?? availableQuantity;

    if (pricing == null || pricing.floorPrice <= 0 || pricing.fairPrice <= 0) {
      _errorMessage =
          languageCode == 'en'
              ? 'Price must be greater than ₹0 before publishing'
              : 'मूल्य 0 से अधिक होना चाहिए / Price must be greater than ₹0 before publishing';
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
        final returnedRaw = response['raw_image_url'] as String?;
        final returnedStudio = response['studio_image_url'] as String?;
        _currentItem = _currentItem!.copyWith(
          status: CatalogStatus.published,
          rawImagePath: (returnedRaw != null && returnedRaw.isNotEmpty)
              ? returnedRaw
              : _currentItem!.rawImagePath,
          studioImagePath: (returnedStudio != null && returnedStudio.isNotEmpty)
              ? returnedStudio
              : _currentItem!.studioImagePath,
        );
        await _storageService.saveCatalog(_currentItem!);
        _updateSavedList(_currentItem!);
        _publishSuccess = true;
        HapticFeedback.heavyImpact();

        _isPublishing = false;
        notifyListeners();

        if (!silent) {
          // Non-blocking confirmation TTS in the user's selected language so the
          // confirmation dialog appears immediately rather than after speech ends.
          unawaited(
            _speakConfirmation(
              textEn: 'Your craft listing is now published on ONDC.',
              textHi: 'आपका उत्पाद ओएनडीसी पर प्रकाशित हो गया है।',
              languageCode: languageCode,
            ),
          );
        }
        return;
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
    provider
        .resolve(ImageConfiguration.empty)
        .addListener(
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
