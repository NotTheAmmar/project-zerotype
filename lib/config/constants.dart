import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String? _getEnv(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  // API
  static String get baseUrl =>
      _getEnv('API_BASE_URL') ?? 'https://api.bazaarsetu.in/v1';
  static bool get useMockData =>
      (_getEnv('USE_MOCK_DATA') ?? 'true').toLowerCase() == 'true';
  static Duration get apiTimeout => const Duration(seconds: 120);

  // AI Extraction (Qwen / Gemini)
  static String get aiExtractionProvider =>
      _getEnv('AI_EXTRACTION_PROVIDER')?.toLowerCase() ?? 'groq_qwen';
  static String get groqApiKey => _getEnv('GROQ_API_KEY') ?? '';
  static String get qwenModel =>
      _getEnv('QWEN_MODEL') ?? 'qwen/qwen3.8-27b';
  static String get qwenApiUrl =>
      _getEnv('QWEN_API_URL') ?? 'https://api.groq.com/openai/v1/chat/completions';

  // Gemini (Fallback)
  static String get geminiApiKey => _getEnv('GEMINI_API_KEY') ?? '';
  static String get geminiModel =>
      _getEnv('GEMINI_MODEL') ?? 'gemini-2.5-flash';

  // Bhashini (Bhashini Cloud)
  static String get bhashiniApiKey => _getEnv('BHASHINI_API_KEY') ?? '';
  static String get bhashiniUlcaKey => _getEnv('BHASHINI_ULCA_KEY') ?? '';
  static String get bhashiniApiUrl =>
      _getEnv('BHASHINI_API_URL') ?? 'https://dhruva-api.bhashini.gov.in';
  static String get bhashiniUserId => _getEnv('BHASHINI_USER_ID') ?? '';
  static String get bhashiniPipelineId =>
      _getEnv('BHASHINI_PIPELINE_ID') ?? '64392f96daac500b55c543cd';
  static String get voicePipeline =>
      _getEnv('VOICE_PIPELINE')?.toLowerCase() ?? 'auto';

  // ── BPP Backend (ONDC Beckn Provider Platform) ────────────────────
  static String get bppBackendUrl {
    final url = _getEnv('BPP_BACKEND_URL') ?? 'http://localhost:8000';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get backendUrl {
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
