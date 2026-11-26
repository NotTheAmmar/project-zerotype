import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';
import '../services/bhashini_service.dart';

enum LanguageDisplayMode { single, bilingual }

class LanguageOption {
  final String code;
  final String nativeName;
  final String englishName;
  final String ttsLocale;
  final bool supportsAsr;
  final bool supportsTts;

  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.ttsLocale,
    this.supportsAsr = true,
    this.supportsTts = false,
  });
}

class LanguageController extends ChangeNotifier {
  static const String _prefKey = 'bazaarsetu_user_language';
  static const String _prefSetupKey = 'bazaarsetu_language_setup_done';
  static const String _prefModeKey = 'bazaarsetu_language_mode';
  static const String _prefPrimaryKey = 'bazaarsetu_primary_language';
  static const String _prefSecondaryKey = 'bazaarsetu_secondary_language';

  /// All 23 languages supported by Bhashini (22 Scheduled Indian Languages + English).
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'hi',
      nativeName: 'हिंदी',
      englishName: 'Hindi',
      ttsLocale: 'hi-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'en',
      nativeName: 'English',
      englishName: 'English',
      ttsLocale: 'en-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'mr',
      nativeName: 'मराठी',
      englishName: 'Marathi',
      ttsLocale: 'mr-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'gu',
      nativeName: 'ગુજરાતી',
      englishName: 'Gujarati',
      ttsLocale: 'gu-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'bn',
      nativeName: 'বাংলা',
      englishName: 'Bengali',
      ttsLocale: 'bn-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'ta',
      nativeName: 'தமிழ்',
      englishName: 'Tamil',
      ttsLocale: 'ta-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'te',
      nativeName: 'తెలుగు',
      englishName: 'Telugu',
      ttsLocale: 'te-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'kn',
      nativeName: 'ಕನ್ನಡ',
      englishName: 'Kannada',
      ttsLocale: 'kn-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'ml',
      nativeName: 'മലയാളം',
      englishName: 'Malayalam',
      ttsLocale: 'ml-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'or',
      nativeName: 'ଓଡ଼ିଆ',
      englishName: 'Odia',
      ttsLocale: 'or-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'pa',
      nativeName: 'ਪੰਜਾਬੀ',
      englishName: 'Punjabi',
      ttsLocale: 'pa-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'as',
      nativeName: 'অসমীয়া',
      englishName: 'Assamese',
      ttsLocale: 'as-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'ur',
      nativeName: 'اردو',
      englishName: 'Urdu',
      ttsLocale: 'ur-IN',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'brx',
      nativeName: "बर'",
      englishName: 'Bodo',
      ttsLocale: 'hi-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'doi',
      nativeName: 'डोगरी',
      englishName: 'Dogri',
      ttsLocale: 'hi-IN',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'ks',
      nativeName: 'कॉशुर',
      englishName: 'Kashmiri',
      ttsLocale: 'ur-IN',
      supportsAsr: false,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'kok',
      nativeName: 'कोंकणी',
      englishName: 'Konkani',
      ttsLocale: 'mr-IN',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'mai',
      nativeName: 'मैथिली',
      englishName: 'Maithili',
      ttsLocale: 'hi-IN',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'mni',
      nativeName: 'ꯃꯩꯇꯩꯂꯣꯟ',
      englishName: 'Manipuri (Meitei)',
      ttsLocale: 'en-IN',
      supportsAsr: true,
      supportsTts: true,
    ),
    LanguageOption(
      code: 'ne',
      nativeName: 'नेपाली',
      englishName: 'Nepali',
      ttsLocale: 'ne-NP',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'sa',
      nativeName: 'संस्कृतम्',
      englishName: 'Sanskrit',
      ttsLocale: 'hi-IN',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'sat',
      nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ',
      englishName: 'Santali',
      ttsLocale: 'hi-IN',
      supportsAsr: true,
      supportsTts: false,
    ),
    LanguageOption(
      code: 'sd',
      nativeName: 'सिन्धी',
      englishName: 'Sindhi',
      ttsLocale: 'hi-IN',
      supportsAsr: false,
      supportsTts: false,
    ),
  ];

  LanguageDisplayMode _displayMode = LanguageDisplayMode.bilingual;
  String _primaryLanguageCode = 'en';
  String? _secondaryLanguageCode = 'hi';
  String _currentLanguageCode = 'hi';
  bool _isLanguageSetupDone = false;
  bool _isLoaded = false;
  Future<void>? _initFuture;

  // In-memory Bhashini NMT translation cache: "<targetLang>::<sourceText>" -> translated
  final Map<String, String> _translationCache = {};
  final Set<String> _pendingTranslations = {};
  final BhashiniService _bhashiniService = BhashiniService();

  LanguageDisplayMode get displayMode => _displayMode;
  bool get isBilingual => _displayMode == LanguageDisplayMode.bilingual;
  String get primaryLanguageCode => _primaryLanguageCode;
  String? get secondaryLanguageCode =>
      isBilingual ? _secondaryLanguageCode : null;

  /// Legacy-compatible active regional/selected language code.
  String get currentLanguageCode => _currentLanguageCode;
  bool get isLanguageSetupDone => _isLanguageSetupDone;
  bool get isLoaded => _isLoaded;

  LanguageOption languageByCode(String code) => supportedLanguages.firstWhere(
    (l) => l.code == code,
    orElse: () => supportedLanguages.first,
  );

  LanguageOption get primaryLanguage => languageByCode(_primaryLanguageCode);

  LanguageOption? get secondaryLanguage => isBilingual &&
          _secondaryLanguageCode != null &&
          _secondaryLanguageCode!.isNotEmpty
      ? languageByCode(_secondaryLanguageCode!)
      : null;

  LanguageOption get currentLanguage => languageByCode(_currentLanguageCode);

  /// Preferred language code for ASR/TTS voice interaction.
  String get voiceLanguageCode {
    if (_primaryLanguageCode != 'en') return _primaryLanguageCode;
    if (isBilingual &&
        _secondaryLanguageCode != null &&
        _secondaryLanguageCode != 'en') {
      return _secondaryLanguageCode!;
    }
    return _primaryLanguageCode;
  }

  /// Concise label shown in top app bar pill.
  String get headerBadgeLabel {
    if (!isBilingual || secondaryLanguage == null) {
      return primaryLanguage.nativeName;
    }
    return '${primaryLanguage.nativeName} + ${secondaryLanguage!.nativeName}';
  }

  LanguageController({bool autoLoad = true}) {
    if (autoLoad) {
      _initFuture = loadLanguagePreference();
    }
  }

  Future<void> loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLegacy = prefs.getString(_prefKey);
      final savedMode = prefs.getString(_prefModeKey);
      final savedPrimary = prefs.getString(_prefPrimaryKey);
      final savedSecondary = prefs.getString(_prefSecondaryKey);

      if (savedMode != null) {
        _displayMode = savedMode == 'single'
            ? LanguageDisplayMode.single
            : LanguageDisplayMode.bilingual;
        _primaryLanguageCode = savedPrimary ?? savedLegacy ?? 'en';
        _secondaryLanguageCode = _displayMode == LanguageDisplayMode.bilingual
            ? (savedSecondary ??
                  (_primaryLanguageCode == 'hi' ? 'en' : 'hi'))
            : null;
        _currentLanguageCode = _computeLegacyCurrentCode();
      } else {
        // Legacy migration path
        final legacyCode = savedLegacy ?? 'hi';
        _currentLanguageCode = legacyCode;
        if (legacyCode == 'en') {
          _displayMode = LanguageDisplayMode.bilingual;
          _primaryLanguageCode = 'en';
          _secondaryLanguageCode = 'hi';
        } else {
          _displayMode = LanguageDisplayMode.bilingual;
          _primaryLanguageCode = 'en';
          _secondaryLanguageCode = legacyCode;
        }
      }

      _isLanguageSetupDone = prefs.getBool(_prefSetupKey) ?? false;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[LanguageController] Error loading language preference: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  String _computeLegacyCurrentCode() {
    if (_displayMode == LanguageDisplayMode.single) {
      return _primaryLanguageCode;
    }
    if (_primaryLanguageCode == 'en' &&
        _secondaryLanguageCode != null &&
        _secondaryLanguageCode!.isNotEmpty) {
      return _secondaryLanguageCode!;
    }
    return _primaryLanguageCode;
  }

  Future<void> setLanguagePreferences({
    required LanguageDisplayMode mode,
    required String primaryCode,
    String? secondaryCode,
  }) async {
    if (_initFuture != null) {
      await _initFuture;
    }

    _displayMode = mode;
    _primaryLanguageCode = primaryCode;
    if (mode == LanguageDisplayMode.bilingual) {
      final fallbackSecond = primaryCode == 'hi' ? 'en' : 'hi';
      _secondaryLanguageCode =
          (secondaryCode != null &&
              secondaryCode.isNotEmpty &&
              secondaryCode != primaryCode)
          ? secondaryCode
          : fallbackSecond;
    } else {
      _secondaryLanguageCode = null;
    }
    _currentLanguageCode = _computeLegacyCurrentCode();
    _isLanguageSetupDone = true;
    _isLoaded = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefModeKey,
        mode == LanguageDisplayMode.single ? 'single' : 'bilingual',
      );
      await prefs.setString(_prefPrimaryKey, _primaryLanguageCode);
      if (_secondaryLanguageCode != null) {
        await prefs.setString(_prefSecondaryKey, _secondaryLanguageCode!);
      } else {
        await prefs.remove(_prefSecondaryKey);
      }
      await prefs.setString(_prefKey, _currentLanguageCode);
      await prefs.setBool(_prefSetupKey, true);
    } catch (e) {
      debugPrint('[LanguageController] Error saving language preference: $e');
    }
  }

  /// Legacy single-code setter preserved for compatibility.
  Future<void> setLanguage(String code) async {
    await setLanguagePreferences(
      mode: code == 'en'
          ? LanguageDisplayMode.single
          : LanguageDisplayMode.bilingual,
      primaryCode: code == 'en' ? 'en' : 'en',
      secondaryCode: code == 'en' ? null : code,
    );
  }

  String? getCachedTranslation(String sourceText, {required String targetLang}) {
    final trimmed = sourceText.trim();
    if (trimmed.isEmpty) return null;
    return _translationCache['$targetLang::$trimmed'];
  }

  /// Lazily translates [sourceText] to [targetLang] using Bhashini NMT when
  /// API credentials are configured, notifying listeners once available.
  void requestTranslation(
    String sourceText, {
    required String sourceLang,
    required String targetLang,
  }) {
    final trimmed = sourceText.trim();
    if (trimmed.isEmpty || sourceLang == targetLang) return;
    if (AppConstants.bhashiniApiKey.isEmpty) return;

    final cacheKey = '$targetLang::$trimmed';
    if (_translationCache.containsKey(cacheKey) ||
        _pendingTranslations.contains(cacheKey)) {
      return;
    }
    _pendingTranslations.add(cacheKey);

    unawaited(() async {
      try {
        final translated = await _bhashiniService.translate(
          trimmed,
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );
        if (translated.isNotEmpty) {
          _translationCache[cacheKey] = translated;
          notifyListeners();
        }
      } catch (e) {
        debugPrint(
          '[LanguageController] Bhashini NMT ($sourceLang->$targetLang) skipped: $e',
        );
      } finally {
        _pendingTranslations.remove(cacheKey);
      }
    }());
  }

  @override
  void dispose() {
    _bhashiniService.dispose();
    super.dispose();
  }
}
