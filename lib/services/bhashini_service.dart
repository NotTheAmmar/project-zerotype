import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BHASHINI NMT SERVICE (Translation Only)
//
// Wraps the two-step Bhashini / Dhruva NMT API pattern:
//   1. Pipeline Config  — discovers per-language NMT service IDs
//   2. Pipeline Compute — translates text across all 23 supported languages
//
// Configs are cached per (translation:sourceLanguage:targetLanguage) key so
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

  // ── Public API (NMT Translation) ─────────────────────────────────────────

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

  void dispose() {
    _client.close();
  }
}
