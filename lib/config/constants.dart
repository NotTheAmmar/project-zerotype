import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  AppConstants._();

  static const String defaultRenderBppUrl =
      'https://project-zerotype-bpp.onrender.com';

  static String? _customKaggleUrl;
  static String? _customQwenApiKey;

  static Future<void> loadCustomConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final kagglePref = prefs.getString('custom_kaggle_url');
      final legacyPref = prefs.getString('custom_backend_url');
      if (kagglePref != null && kagglePref.trim().isNotEmpty) {
        _customKaggleUrl = kagglePref.trim().replaceAll(RegExp(r'/+$'), '');
      } else if (legacyPref != null && legacyPref.trim().isNotEmpty) {
        // Migrate legacy override to Kaggle-only URL so Render BPP stays intact.
        _customKaggleUrl = legacyPref.trim().replaceAll(RegExp(r'/+$'), '');
        await prefs.setString('custom_kaggle_url', _customKaggleUrl!);
        await prefs.remove('custom_backend_url');
      } else {
        _customKaggleUrl = null;
      }
      _customQwenApiKey = prefs.getString('custom_qwen_api_key');
    } catch (_) {}
  }

  static Future<void> setCustomKaggleUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _customKaggleUrl = cleanUrl.isNotEmpty ? cleanUrl : null;
    if (_customKaggleUrl != null) {
      await prefs.setString('custom_kaggle_url', _customKaggleUrl!);
    } else {
      await prefs.remove('custom_kaggle_url');
    }
    await prefs.remove('custom_backend_url');
  }

  /// Legacy alias kept for compatibility — sets the optional Kaggle GPU URL
  /// without ever hijacking the persistent Render BPP / Supabase backend.
  static Future<void> setCustomBackendUrl(String url) =>
      setCustomKaggleUrl(url);

  static Future<void> setCustomQwenApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanKey = key.trim();
    _customQwenApiKey = cleanKey.isNotEmpty ? cleanKey : null;
    if (_customQwenApiKey != null) {
      await prefs.setString('custom_qwen_api_key', _customQwenApiKey!);
    } else {
      await prefs.remove('custom_qwen_api_key');
    }
  }

  static String? _getEnv(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  static String _trimTrailingSlash(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  // API
  static String get baseUrl =>
      _getEnv('API_BASE_URL') ?? 'https://api.bazaarsetu.in/v1';

  static Duration get apiTimeout => const Duration(seconds: 120);

  // AI Extraction (Qwen LLM)
  static String get aiExtractionProvider =>
      _getEnv('AI_EXTRACTION_PROVIDER')?.toLowerCase() ?? 'qwen';

  static String get qwenApiKey {
    if (_customQwenApiKey != null && _customQwenApiKey!.isNotEmpty) {
      return _customQwenApiKey!;
    }
    return _getEnv('QWEN_API_KEY') ?? '';
  }

  static String get qwenModel =>
      _getEnv('QWEN_MODEL') ?? 'qwen-2.5-32b-instruct';
  static String get qwenApiUrl =>
      _getEnv('QWEN_API_URL') ??
      'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions';

  // Bhashini (Bhashini Cloud)
  static String get bhashiniApiKey => _getEnv('BHASHINI_API_KEY') ?? '';
  static String get bhashiniUlcaKey => _getEnv('BHASHINI_ULCA_KEY') ?? '';
  static String get bhashiniApiUrl =>
      _getEnv('BHASHINI_API_URL') ?? 'https://dhruva-api.bhashini.gov.in';
  static String get bhashiniUserId => _getEnv('BHASHINI_USER_ID') ?? '';
  static String get bhashiniPipelineId =>
      _getEnv('BHASHINI_PIPELINE_ID') ?? '64392f96daac500b55c543cd';

  // ── Persistent BPP Backend (Render ONDC + Supabase DB + Storage) ───────────
  /// Always points to the 24/7 ONDC BPP / Supabase backend and is never
  /// overridden by the temporary Kaggle GPU tunnel URL.
  static String get bppBackendUrl {
    final envUrl = _trimTrailingSlash(_getEnv('BPP_BACKEND_URL') ?? '');
    if (envUrl.isNotEmpty) return envUrl;
    return defaultRenderBppUrl;
  }

  // ── Optional Temporary Kaggle GPU Server (BiRefNet Studio Processing) ──────
  /// Returns the active Kaggle GPU tunnel URL when configured, or an empty
  /// string when offline/unconfigured.
  static String get kaggleUrl {
    if (_customKaggleUrl != null && _customKaggleUrl!.isNotEmpty) {
      return _customKaggleUrl!;
    }
    final explicitKaggle = _trimTrailingSlash(_getEnv('KAGGLE_URL') ?? '');
    if (explicitKaggle.isNotEmpty) return explicitKaggle;

    final envBackend = _trimTrailingSlash(_getEnv('BACKEND_URL') ?? '');
    if (envBackend.isNotEmpty && envBackend != bppBackendUrl) {
      return envBackend;
    }
    return '';
  }

  static String get backendUrl => kaggleUrl.isNotEmpty ? kaggleUrl : bppBackendUrl;

  // Audio — Open-ended voice input (no strict time limit)
  static const int maxRecordingSeconds = 3600; // 1 hour max safety buffer
  static const int audioSampleRate = 16000;
  static const int ttsSampleRate = 22050;
  static const double silenceAmplitudeThreshold = -50.0; // dBFS

  // Image quality thresholds
  static const double blurVarianceThreshold = 100.0;
  static const double lowLightLuminanceThreshold = 40.0;

  // Pricing defaults
  static const int defaultDailyWageRate = 500; // ₹/day
  static const double overheadPercent = 0.10;
  static const double fairPriceMultiplier = 1.50;
  static const double premiumPriceMultiplier = 1.20;

  // Mock data delay (simulates inference latency)
  static const Duration mockStage1Delay = Duration(milliseconds: 1500);
  static const Duration mockStage2Delay = Duration(milliseconds: 1800);
  static const Duration mockStage3Delay = Duration(milliseconds: 1000);
}
