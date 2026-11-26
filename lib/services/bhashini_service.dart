import 'package:cross_file/cross_file.dart';

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
//   1. Pipeline Config  — discovers per-language model service IDs
//   2. Pipeline Compute — runs ASR / NMT / TTS / Transliteration inference
//
// Configs are cached per (taskType, sourceLanguage, targetLanguage) key so
// switching languages never reuses another language's model serviceId.
// ─────────────────────────────────────────────────────────────────────────────

class BhashiniException implements Exception {
  const BhashiniException(this.message);
  final String message;

  @override
  String toString() => 'BhashiniException: $message';
}

class _CachedTaskConfig {
  final String serviceId;
  final String inferenceUrl;
  final String? inferenceApiKey;

  const _CachedTaskConfig({
    required this.serviceId,
    required this.inferenceUrl,
    this.inferenceApiKey,
  });
}

class BhashiniService {
  BhashiniService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ── Config cache keyed by "<taskType>:<sourceLanguage>:<targetLanguage>" ───
  final Map<String, _CachedTaskConfig> _taskConfigs = {};

  String _cacheKey(
    String taskType,
    String sourceLanguage, [
    String? targetLanguage,
  ]) => '$taskType:$sourceLanguage:${targetLanguage ?? ''}';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Transcribes audio at [audioPath] from [sourceLanguage] (BCP-47, e.g. "hi").
  /// Returns the recognised text string.
  Future<String> transcribe(
    String audioPath, {
    String sourceLanguage = 'hi',
  }) async {
    final cfg = await _ensureConfig(
      taskType: 'asr',
      sourceLanguage: sourceLanguage,
    );

    final audioBytes = await _readAudio(audioPath);
    final base64Audio = base64Encode(audioBytes);
    final audioFormat = audioPath.toLowerCase().endsWith('.flac')
        ? 'flac'
        : 'wav';

    Map<String, dynamic> result;
    try {
      // Request Inverse Text Normalization & punctuation so spoken numbers
      // become digits (e.g. "तीन सौ पचास" -> "350") for accurate Qwen extraction.
      result = await _compute(
        taskConfig: cfg,
        pipelineTasks: [
          {
            'taskType': 'asr',
            'config': {
              'language': {'sourceLanguage': sourceLanguage},
              'serviceId': cfg.serviceId,
              'audioFormat': audioFormat,
              'samplingRate': AppConstants.audioSampleRate,
              'postProcessors': const ['itn', 'punctuation'],
            },
          },
        ],
        inputData: {
          'audio': [
            {'audioContent': base64Audio},
          ],
        },
      );
    } on BhashiniException {
      // Fallback retry without postProcessors if a minor language rejects them.
      result = await _compute(
        taskConfig: cfg,
        pipelineTasks: [
          {
            'taskType': 'asr',
            'config': {
              'language': {'sourceLanguage': sourceLanguage},
              'serviceId': cfg.serviceId,
              'audioFormat': audioFormat,
              'samplingRate': AppConstants.audioSampleRate,
            },
          },
        ],
        inputData: {
          'audio': [
            {'audioContent': base64Audio},
          ],
        },
      );
    }

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
    final cfg = await _ensureConfig(
      taskType: 'translation',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    final result = await _compute(
      taskConfig: cfg,
      pipelineTasks: [
        {
          'taskType': 'translation',
          'config': {
            'language': {
              'sourceLanguage': sourceLanguage,
              'targetLanguage': targetLanguage,
            },
            'serviceId': cfg.serviceId,
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

  /// Synthesises speech for [text] in [sourceLanguage] at 22.05 kHz.
  /// Converts Bhashini's 32-bit IEEE float WAV output to 16-bit PCM WAV so
  /// Android/mobile audio players play crisply without clipping or distortion.
  Future<String> synthesize(
    String text, {
    String sourceLanguage = 'hi',
    String gender = 'female',
  }) async {
    final cfg = await _ensureConfig(
      taskType: 'tts',
      sourceLanguage: sourceLanguage,
    );

    final result = await _compute(
      taskConfig: cfg,
      pipelineTasks: [
        {
          'taskType': 'tts',
          'config': {
            'language': {'sourceLanguage': sourceLanguage},
            'serviceId': cfg.serviceId,
            'gender': gender,
            'samplingRate': AppConstants.ttsSampleRate,
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
        result['pipelineResponse']?[0]?['audio']?[0]?['audioContent']
            as String?;
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
    final cfg = await _ensureConfig(
      taskType: 'transliteration',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );

    final result = await _compute(
      taskConfig: cfg,
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
            'serviceId': cfg.serviceId,
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

  // ── Config (per-language cached) ─────────────────────────────────────────

  Future<_CachedTaskConfig> _ensureConfig({
    required String taskType,
    String sourceLanguage = 'hi',
    String? targetLanguage,
  }) async {
    final key = _cacheKey(taskType, sourceLanguage, targetLanguage);
    final existing = _taskConfigs[key];
    if (existing != null) return existing;

    final pipelineTask = <String, dynamic>{
      'taskType': taskType,
      'config': {
        'language': {
          'sourceLanguage': sourceLanguage,
          'targetLanguage': ?targetLanguage,
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

    final callbackUrl =
        body['pipelineInferenceAPIEndPoint']?['callbackUrl'] as String?;
    final inferenceUrl = (callbackUrl != null && callbackUrl.isNotEmpty)
        ? callbackUrl
        : '${AppConstants.bhashiniApiUrl}/services/inference/pipeline';

    final apiKey =
        body['pipelineInferenceAPIEndPoint']?['inferenceApiKey']?['value']
            as String?;

    String resolvedServiceId = '';
    final taskConfigs = body['pipelineResponseConfig'] as List?;
    if (taskConfigs != null) {
      for (final taskCfg in taskConfigs) {
        final type = taskCfg['taskType'] as String?;
        final configs = taskCfg['config'] as List?;
        if (type == taskType && configs != null && configs.isNotEmpty) {
          final serviceId = configs.first['serviceId'] as String?;
          if (serviceId != null && serviceId.isNotEmpty) {
            resolvedServiceId = serviceId;
            break;
          }
        }
      }
    }

    if (resolvedServiceId.isEmpty) {
      throw BhashiniException(
        'No serviceId available for $taskType ($sourceLanguage${targetLanguage != null ? "->$targetLanguage" : ""})',
      );
    }

    final cached = _CachedTaskConfig(
      serviceId: resolvedServiceId,
      inferenceUrl: inferenceUrl,
      inferenceApiKey: (apiKey != null && apiKey.isNotEmpty) ? apiKey : null,
    );
    _taskConfigs[key] = cached;

    debugPrint('[BhashiniService] Config OK [$key] -> $resolvedServiceId');
    return cached;
  }

  // ── Compute ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _compute({
    required _CachedTaskConfig taskConfig,
    required List<Map<String, dynamic>> pipelineTasks,
    required Map<String, dynamic> inputData,
  }) async {
    final url = taskConfig.inferenceUrl;
    final authValue = taskConfig.inferenceApiKey?.isNotEmpty == true
        ? taskConfig.inferenceApiKey!
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
      final bodyStr = response.body;
      debugPrint(
        'Body: ${bodyStr.length > 500 ? "${bodyStr.substring(0, 500)}..." : bodyStr}',
      );
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
    if (kIsWeb ||
        audioPath.startsWith('blob:') ||
        audioPath.startsWith('http')) {
      final xFile = XFile(audioPath);
      return await xFile.readAsBytes();
    }
    return File(audioPath).readAsBytes();
  }

  /// Converts 32-bit IEEE float RIFF WAV (format tag 3, returned by Bhashini
  /// indic-tts-coqui models) into standard 16-bit signed PCM WAV (format tag 1)
  /// so mobile audio decoders play cleanly without distortion or clipping.
  static Uint8List normalizeWavToPcm16(Uint8List bytes) {
    if (bytes.length < 44) return bytes;
    // Check 'RIFF' and 'WAVE'
    if (bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46 ||
        bytes[8] != 0x57 ||
        bytes[9] != 0x41 ||
        bytes[10] != 0x56 ||
        bytes[11] != 0x45) {
      return bytes;
    }

    final src = ByteData.sublistView(bytes);
    int offset = 12;
    int audioFormat = 1;
    int channels = 1;
    int sampleRate = 22050;
    int bitsPerSample = 16;
    int dataOffset = -1;
    int dataSize = 0;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = src.getUint32(offset + 4, Endian.little);
      final chunkDataStart = offset + 8;

      if (chunkId == 'fmt ' && chunkSize >= 16 && chunkDataStart + 16 <= bytes.length) {
        audioFormat = src.getUint16(chunkDataStart, Endian.little);
        channels = src.getUint16(chunkDataStart + 2, Endian.little);
        sampleRate = src.getUint32(chunkDataStart + 4, Endian.little);
        bitsPerSample = src.getUint16(chunkDataStart + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataStart;
        dataSize = chunkSize.clamp(0, bytes.length - chunkDataStart);
        break;
      }

      // RIFF chunks are word-aligned (padded to even byte boundary)
      offset = chunkDataStart + chunkSize + (chunkSize & 1);
    }

    // Only convert when IEEE 32-bit float (audioFormat == 3 && bitsPerSample == 32)
    if (audioFormat != 3 || bitsPerSample != 32 || dataOffset < 0 || dataSize < 4) {
      return bytes;
    }

    final sampleCount = dataSize ~/ 4;
    final pcmDataSize = sampleCount * 2;
    final out = Uint8List(44 + pcmDataSize);
    final dst = ByteData.view(out.buffer);

    // RIFF header
    out.setAll(0, [0x52, 0x49, 0x46, 0x46]); // 'RIFF'
    dst.setUint32(4, 36 + pcmDataSize, Endian.little);
    out.setAll(8, [0x57, 0x41, 0x56, 0x45]); // 'WAVE'

    // fmt chunk
    out.setAll(12, [0x66, 0x6D, 0x74, 0x20]); // 'fmt '
    dst.setUint32(16, 16, Endian.little); // PCM fmt chunk size
    dst.setUint16(20, 1, Endian.little); // PCM format = 1
    dst.setUint16(22, channels, Endian.little);
    dst.setUint32(24, sampleRate, Endian.little);
    dst.setUint32(28, sampleRate * channels * 2, Endian.little); // byteRate
    dst.setUint16(32, channels * 2, Endian.little); // blockAlign
    dst.setUint16(34, 16, Endian.little); // bitsPerSample

    // data chunk
    out.setAll(36, [0x64, 0x61, 0x74, 0x61]); // 'data'
    dst.setUint32(40, pcmDataSize, Endian.little);

    for (int i = 0; i < sampleCount; i++) {
      final f = src.getFloat32(dataOffset + i * 4, Endian.little);
      final clamped = f.isNaN ? 0.0 : f.clamp(-1.0, 1.0);
      // Apply ~1.4 dB headroom so hot VITS peaks (0.98+) never inter-sample clip on DACs
      final s16 = (clamped * 0.85 * 32767.0).round().clamp(-32768, 32767);
      dst.setInt16(44 + i * 2, s16, Endian.little);
    }

    return out;
  }

  /// Decodes a base64 WAV string, normalizes IEEE-float WAV to 16-bit PCM, and
  /// writes it to a temp file. Returns the file path.
  Future<String> _saveBase64Audio(String base64Audio) async {
    final rawBytes = base64Decode(base64Audio);
    final pcmBytes = normalizeWavToPcm16(rawBytes);
    if (kIsWeb) {
      return 'data:audio/wav;base64,${base64Encode(pcmBytes)}';
    }
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/bhashini_tts_$ts.wav';
    await File(path).writeAsBytes(pcmBytes);
    return path;
  }

  void dispose() {
    _client.close();
  }
}
