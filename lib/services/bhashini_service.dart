import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BHASHINI SERVICE
//
// Wraps the two-step Bhashini / Dhruva API pattern:
//   1. Pipeline Config  — discovers available model service IDs
//   2. Pipeline Compute — runs ASR / NMT / TTS / Transliteration inference
//
// All methods are safe to call concurrently; config is cached after the first
// successful fetch. Throws [BhashiniException] on any API failure.
// ─────────────────────────────────────────────────────────────────────────────

class BhashiniException implements Exception {
  const BhashiniException(this.message);
  final String message;

  @override
  String toString() => 'BhashiniException: $message';
}

class BhashiniService {
  BhashiniService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ── Config cache ─────────────────────────────────────────────────────────

  /// Lazy-loaded pipeline config: task name → serviceId.
  Map<String, String> _serviceIds = {};

  /// The inference URL returned by the config call (may vary by task).
  String? _inferenceUrl;

  bool _configFetched = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Transcribes audio at [audioPath] from [sourceLanguage] (BCP-47, e.g. "hi").
  /// Returns the recognised text string.
  Future<String> transcribe(
    String audioPath, {
    String sourceLanguage = 'hi',
  }) async {
    await _ensureConfig(taskType: 'asr', sourceLanguage: sourceLanguage);

    final audioBytes = await _readAudio(audioPath);
    final base64Audio = base64Encode(audioBytes);

    final result = await _compute(
      pipelineTasks: [
        {
          'taskType': 'asr',
          'config': {
            'language': {'sourceLanguage': sourceLanguage},
            'serviceId': _serviceIds['asr'] ?? '',
            'audioFormat': audioPath.endsWith('.wav') ? 'wav' : 'flac',
            'samplingRate': AppConstants.audioSampleRate,
          },
        },
      ],
      inputData: {
        'audio': [
          {
            'audioContent': base64Audio,
          },
        ],
      },
    );

    final output =
        result['pipelineResponse']?[0]?['output']?[0]?['source'] as String?;
    if (output == null || output.trim().isEmpty) {
      throw const BhashiniException('ASR returned empty transcript');
    }
    return output.trim();
  }

  /// Translates [text] from [sourceLanguage] to [targetLanguage].
  Future<String> translate(
    String text, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    await _ensureConfig(
      taskType: 'translation',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    final result = await _compute(
      pipelineTasks: [
        {
          'taskType': 'translation',
          'config': {
            'language': {
              'sourceLanguage': sourceLanguage,
              'targetLanguage': targetLanguage,
            },
            'serviceId': _serviceIds['translation'] ?? '',
          },
        },
      ],
      inputData: {
        'input': [
          {'source': text},
        ],
      },
    );

    final output =
        result['pipelineResponse']?[0]?['output']?[0]?['target'] as String?;
    if (output == null || output.trim().isEmpty) {
      throw const BhashiniException('NMT returned empty translation');
    }
    return output.trim();
  }

  /// Synthesises speech for [text] in [sourceLanguage].
  /// Returns the local file path of the decoded WAV audio, ready for playback.
  Future<String> synthesize(
    String text, {
    String sourceLanguage = 'hi',
    String gender = 'female',
  }) async {
    await _ensureConfig(taskType: 'tts', sourceLanguage: sourceLanguage);

    final result = await _compute(
      pipelineTasks: [
        {
          'taskType': 'tts',
          'config': {
            'language': {'sourceLanguage': sourceLanguage},
            'serviceId': _serviceIds['tts'] ?? '',
            'gender': gender,
            'samplingRate': 8000,
          },
        },
      ],
      inputData: {
        'input': [
          {'source': text},
        ],
      },
    );

    final base64Audio =
        result['pipelineResponse']?[0]?['audio']?[0]?['audioContent'] as String?;
    if (base64Audio == null || base64Audio.isEmpty) {
      throw const BhashiniException('TTS returned empty audio');
    }

    return _saveBase64Audio(base64Audio);
  }

  /// Transliterates [text] between scripts.
  /// Example: Devanagari "चंदेरी" → Latin "Chanderi".
  Future<String> transliterate(
    String text, {
    required String sourceLanguage,
    required String targetLanguage,
    String sourceScriptCode = 'Deva',
    String targetScriptCode = 'Latn',
  }) async {
    await _ensureConfig(
      taskType: 'transliteration',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    final result = await _compute(
      pipelineTasks: [
        {
          'taskType': 'transliteration',
          'config': {
            'language': {
              'sourceLanguage': sourceLanguage,
              'targetLanguage': targetLanguage,
              'sourceScriptCode': sourceScriptCode,
              'targetScriptCode': targetScriptCode,
            },
            'serviceId': _serviceIds['transliteration'] ?? '',
          },
        },
      ],
      inputData: {
        'input': [
          {'source': text},
        ],
      },
    );

    final output =
        result['pipelineResponse']?[0]?['output']?[0]?['target'] as String?;
    if (output == null || output.trim().isEmpty) {
      throw const BhashiniException('Transliteration returned empty result');
    }
    return output.trim();
  }

  // ── Config (lazy init) ───────────────────────────────────────────────────

  /// Calls the ULCA model search endpoint to discover service IDs and the
  /// inference URL for [taskType]. Results are cached for the session.
  Future<void> _ensureConfig({
    required String taskType,
    String sourceLanguage = 'hi',
    String? targetLanguage,
  }) async {
    if (_configFetched && _serviceIds.containsKey(taskType)) return;

    final pipelineTask = <String, dynamic>{
      'taskType': taskType,
      'config': {
        'language': {
          'sourceLanguage': sourceLanguage,
          if (targetLanguage != null) 'targetLanguage': targetLanguage,
        },
      },
    };

    final uri = Uri.parse(
      'https://meity-auth.ulcacontrib.org/ulca/apis/v0/model/getModelsPipeline',
    );

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'userID': AppConstants.bhashiniUserId,
            'ulcaApiKey': AppConstants.bhashiniUlcaKey,
          },
          body: jsonEncode({
            'pipelineTasks': [pipelineTask],
            'pipelineRequestConfig': {
              'pipelineId': AppConstants.bhashiniPipelineId,
            },
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw BhashiniException(
        'Pipeline config failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract inference URL (can differ per task) — fall back to default
    final callbackUrl = body['pipelineInferenceAPIEndPoint']
        ?['callbackUrl'] as String?;
    _inferenceUrl = (callbackUrl != null && callbackUrl.isNotEmpty)
        ? callbackUrl
        : '${AppConstants.bhashiniApiUrl}/services/inference/pipeline';

    // Extract service IDs per task type from the config response
    final taskConfigs = body['pipelineResponseConfig'] as List?;
    if (taskConfigs != null) {
      for (final taskCfg in taskConfigs) {
        final type = taskCfg['taskType'] as String?;
        final configs = taskCfg['config'] as List?;
        if (type != null && configs != null && configs.isNotEmpty) {
          final serviceId = configs.first['serviceId'] as String?;
          if (serviceId != null && serviceId.isNotEmpty) {
            _serviceIds[type] = serviceId;
          }
        }
      }
    }

    // Also try to read the infer endpoint per-task (Bhashini v2 style)
    final apiKey = body['pipelineInferenceAPIEndPoint']
        ?['inferenceApiKey']?['value'] as String?;
    if (apiKey != null && apiKey.isNotEmpty) {
      // Store separately so compute() can use it
      _inferenceApiKey = apiKey;
    }

    _configFetched = true;
    debugPrint('[BhashiniService] Config OK — serviceIds: $_serviceIds');
    debugPrint('[BhashiniService] Inference URL: $_inferenceUrl');
  }

  String? _inferenceApiKey;

  // ── Compute ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _compute({
    required List<Map<String, dynamic>> pipelineTasks,
    required Map<String, dynamic> inputData,
  }) async {
    final url = _inferenceUrl ??
        '${AppConstants.bhashiniApiUrl}/services/inference/pipeline';

    // Prefer the key from the config response; fall back to the API key from .env
    final authValue =
        _inferenceApiKey?.isNotEmpty == true
            ? _inferenceApiKey!
            : AppConstants.bhashiniApiKey;

    final requestBody = {
      'pipelineTasks': pipelineTasks,
      'inputData': inputData,
    };

    if (kDebugMode) {
      debugPrint('==== BHASHINI REQUEST ====');
      debugPrint('URL: $url');
      debugPrint('Tasks: ${jsonEncode(pipelineTasks)}');
      debugPrint('==========================');
    }

    final response = await _client
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': authValue,
          },
          body: jsonEncode(requestBody),
        )
        .timeout(AppConstants.apiTimeout);

    if (kDebugMode) {
      debugPrint('==== BHASHINI RESPONSE ====');
      debugPrint('Status Code: ${response.statusCode}');
      // Only print first 500 chars to avoid huge base64 spam
      final bodyStr = response.body;
      debugPrint('Body: ${bodyStr.length > 500 ? bodyStr.substring(0, 500) + "..." : bodyStr}');
      debugPrint('===========================');
    }

    if (response.statusCode != 200) {
      throw BhashiniException(
        'Inference failed (${response.statusCode}): ${response.body}',
      );
    }


    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<Uint8List> _readAudio(String audioPath) async {
    if (kIsWeb) {
      final res = await _client.get(Uri.parse(audioPath));
      return res.bodyBytes;
    }
    return File(audioPath).readAsBytes();
  }

  /// Decodes a base64 WAV string and writes it to a temp file.
  /// Returns the file path.
  Future<String> _saveBase64Audio(String base64Audio) async {
    final bytes = base64Decode(base64Audio);
    final dir = kIsWeb ? null : await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir?.path ?? ''}/bhashini_tts_$ts.wav';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  void dispose() {
    _client.close();
  }
}
