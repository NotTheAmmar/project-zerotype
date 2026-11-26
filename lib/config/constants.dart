import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  AppConstants._();

  static String? _customBackendUrl;
  static String? _customQwenApiKey;

  static Future<void> loadCustomConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBackendUrl = prefs.getString('custom_backend_url');
      _customQwenApiKey = prefs.getString('custom_qwen_api_key');
    } catch (_) {}
  }

  static Future<void> setCustomBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    _customBackendUrl = cleanUrl.isNotEmpty ? cleanUrl : null;
    if (_customBackendUrl != null) {
      await prefs.setString('custom_backend_url', _customBackendUrl!);
    } else {
      await prefs.remove('custom_backend_url');
    }
  }

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

  // API
  static String get baseUrl {
    if (_customBackendUrl != null && _customBackendUrl!.isNotEmpty) {
      return _customBackendUrl!;
    }
    return _getEnv('API_BASE_URL') ?? 'https://api.bazaarsetu.in/v1';
  }

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

  // ── BPP Backend (ONDC Beckn Provider Platform) ────────────────────
  static String get bppBackendUrl {
    if (_customBackendUrl != null && _customBackendUrl!.isNotEmpty) {
      return _customBackendUrl!;
    }
    final url = _getEnv('BPP_BACKEND_URL') ?? 'http://localhost:8000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get backendUrl {
    if (_customBackendUrl != null && _customBackendUrl!.isNotEmpty) {
      return _customBackendUrl!;
    }
    final url = _getEnv('BACKEND_URL') ?? 'http://localhost:8000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Audio — Open-ended voice input (no strict time limit)
  static const int maxRecordingSeconds = 3600; // 1 hour max safety buffer
  static const int audioSampleRate = 16000;
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
