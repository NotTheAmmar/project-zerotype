import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String? _getEnv(String key) {
    if (!dotenv.isInitialized) return null;
    return dotenv.env[key];
  }

  // API
  static String get baseUrl =>
      _getEnv('API_BASE_URL') ?? 'https://api.kalakriti.dev/v1';
  static bool get useMockData =>
      (_getEnv('USE_MOCK_DATA') ?? 'true').toLowerCase() == 'true';
  static Duration get apiTimeout => const Duration(seconds: 120);

  // Gemini
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

  // Audio
  static const int maxRecordingSeconds = 60;
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
