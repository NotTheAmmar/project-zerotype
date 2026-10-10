import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';
import '../models/catalog_item.dart';
import '../data/mock_data.dart'; //delete
import 'bhashini_service.dart';

/// Response from the catalog processing pipeline.
class CatalogProcessResult {
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final CraftAttributes? craftAttributes;
  final PricingCorridor? pricing;
  final String? studioImagePath;
  final String? audioReadbackPath;

  const CatalogProcessResult({
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    this.craftAttributes,
    this.pricing,
    this.studioImagePath,
    this.audioReadbackPath,
  });
}

/// Callback to report processing stage progress.
/// stage: 0 = image processing, 1 = voice/NLP, 2 = pricing
typedef StageCallback = void Function(int stage);

/// Abstract service contract.
/// Swap MockApiService → LiveApiService by setting USE_MOCK_DATA=false in .env.
abstract class ApiService {
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  });

  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  });

  factory ApiService() {
    if (AppConstants.useMockData) {
      return MockApiService();
    }
    return LiveApiService();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class MockApiService implements ApiService {
  @override
  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  }) async {
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
    return {
      'status': 'PUBLISHED',
      'catalog_id': item.id,
      'message': 'Mock successful publish',
    };
  }

  int _mockIndex = 0;

  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    final payload = MockData.catalogs[_mockIndex % MockData.catalogs.length];
    _mockIndex++;

    await Future.delayed(AppConstants.mockStage1Delay);
    onStageComplete?.call(0);

    await Future.delayed(AppConstants.mockStage2Delay);
    onStageComplete?.call(1);

    await Future.delayed(AppConstants.mockStage3Delay);
    onStageComplete?.call(2);

    return CatalogProcessResult(
      titleEn: payload.titleEn,
      titleHi: payload.titleHi,
      descriptionEn: payload.descriptionEn,
      descriptionHi: payload.descriptionHi,
      craftAttributes: payload.craftAttributes,
      pricing: payload.pricing,
      studioImagePath: payload.studioImagePath ?? payload.rawImagePath,
      audioReadbackPath: null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

class LiveApiService implements ApiService {
  @override
  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  }) async {
    final uri = Uri.parse('${AppConstants.bppBackendUrl}/api/v1/bpp/publish');

    final body = {
      'catalog_id': item.id,
      'artisan_name': item.craftAttributes?.artisanName ?? 'KalaKriti Artisan',
      'cluster_name':
          item.craftAttributes?.clusterLocation ?? 'Chanderi Handloom Cluster',
      'title_en': item.titleEn ?? '',
      'title_hi': item.titleHi ?? '',
      'description_en': item.descriptionEn ?? '',
      'description_hi': item.descriptionHi ?? '',
      'craft_category': item.craftAttributes?.category ?? 'Handloom Silk',
      'category_id': 'ONDC:RET12',
      'materials': item.craftAttributes?.materials ?? [],
      'dimensions': item.craftAttributes?.dimensions ?? '1 unit',
      'floor_price': pricing.floorPrice.toDouble(),
      'fair_price': pricing.fairPrice.toDouble(),
      'premium_price': pricing.premiumPrice.toDouble(),
      'studio_image_url':
          item.studioImagePath ??
          'https://images.unsplash.com/photo-1610030469983-98e550d6193c',
      'available_qty': availableQuantity,
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'bypass-tunnel-reminder': 'true',
          },
          body: jsonEncode(body),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Publish failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    return _processViaBhashini(
      imagePath: imagePath,
      audioPath: audioPath,
      onStageComplete: onStageComplete,
    );
  }

  // ── Bhashini Cloud (direct client-side calls, no backend) ────────

  final BhashiniService _bhashiniService = BhashiniService();

  Future<CatalogProcessResult> _processViaBhashini({
    required String imagePath,
    required String audioPath,
    StageCallback? onStageComplete,
  }) async {
    _assertKey('BHASHINI_API_KEY', AppConstants.bhashiniApiKey);
    _assertKey('GEMINI_API_KEY', AppConstants.geminiApiKey);

    // Stage 0: image processing (runs in parallel via CatalogController)
    onStageComplete?.call(0);

    // ── Step 1: Bhashini ASR — audio → Hindi transcript ──
    final hindiTranscript = await _bhashiniService.transcribe(audioPath);
    debugPrint('[Bhashini] ASR transcript: $hindiTranscript');

    // ── Step 2: Bhashini NMT — Hindi → English (so Gemini can extract reliably) ──
    final englishTranscript = await _bhashiniService.translate(
      hindiTranscript,
      sourceLanguage: 'hi',
      targetLanguage: 'en',
    );
    debugPrint('[Bhashini] NMT hi→en: $englishTranscript');

    // Stage 1: transcription + translation done
    onStageComplete?.call(1);

    // ── Step 3: Gemini — structured catalog JSON extraction from English text ──
    final extracted = await _extractWithGemini(englishTranscript);

    // ── Step 4: Bhashini NMT — English description → Hindi (for readback TTS) ──
    final descEn = extracted['descriptor']?['long_desc'] as String? ?? '';
    String descHi = '';
    if (descEn.isNotEmpty) {
      try {
        descHi = await _bhashiniService.translate(
          descEn,
          sourceLanguage: 'en',
          targetLanguage: 'hi',
        );
      } catch (_) {
        // Non-fatal: fall back to Gemini's own Hindi description tag
        descHi = _getTagValue(extracted, 'translation_hi', 'long_desc') ?? '';
      }
    } else {
      descHi = _getTagValue(extracted, 'translation_hi', 'long_desc') ?? '';
    }

    // Stage 2: extraction + pricing done
    onStageComplete?.call(2);

    return _resultFromBhashiniExtraction(extracted, descHi: descHi);
  }

  CatalogProcessResult _resultFromBhashiniExtraction(
    Map<String, dynamic> j, {
    required String descHi,
  }) {
    final materialsStr = _getTagValue(j, 'craft_attributes', 'materials') ?? '';
    final materialsList = materialsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final laborDays =
        _parseInt(_getTagValue(j, 'pricing_inputs', 'labor_days')) ?? 0;
    final rawCost =
        _parseInt(_getTagValue(j, 'pricing_inputs', 'raw_material_cost')) ?? 0;

    final pricing = PricingCorridor.compute(
      rawMaterialCost: rawCost,
      laborDays: laborDays,
    );

    return CatalogProcessResult(
      titleEn: j['descriptor']?['name'] as String?,
      titleHi: _getTagValue(j, 'translation_hi', 'name'),
      descriptionEn: j['descriptor']?['long_desc'] as String?,
      descriptionHi: descHi.isNotEmpty
          ? descHi
          : _getTagValue(j, 'translation_hi', 'long_desc'),
      craftAttributes: CraftAttributes(
        category: _getTagValue(j, 'craft_attributes', 'category'),
        materials: materialsList,
        laborDays: laborDays,
        clusterLocation: _getTagValue(
          j,
          'craft_attributes',
          'cluster_location',
        ),
        artisanName: _getTagValue(j, 'statutory_info', 'manufacturer_name'),
        countryOfOrigin: _getTagValue(j, 'statutory_info', 'country_of_origin'),
        netQuantity: _getTagValue(j, 'statutory_info', 'net_quantity'),
        genericName: _getTagValue(j, 'statutory_info', 'generic_name'),
      ),
      pricing: pricing,
    );
  }

  /// Navigates the Gemini ONDC tag list structure: tags[code=groupCode].list[code=code].value
  static String? _getTagValue(
    Map<String, dynamic> j,
    String groupCode,
    String code,
  ) {
    final tags = j['tags'] as List?;
    if (tags == null) return null;
    for (final tagGroup in tags) {
      if (tagGroup is Map && tagGroup['code'] == groupCode) {
        final list = tagGroup['list'] as List?;
        if (list != null) {
          for (final item in list) {
            if (item is Map && item['code'] == code) {
              return item['value']?.toString();
            }
          }
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _extractWithGemini(String transcript) async {
    final model = AppConstants.geminiModel;
    final key = AppConstants.geminiApiKey;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': _geminiSystemInstruction},
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': transcript},
                ],
              },
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.2, // low temp for consistent structured output
            },
          }),
        )
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini extraction failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Navigate Gemini response envelope
    final text =
        (body['candidates'] as List?)?.first['content']['parts']?.first['text']
            as String?;

    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned empty extraction response.');
    }

    return jsonDecode(text) as Map<String, dynamic>;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _assertKey(String name, String value) {
    if (value.isEmpty) {
      throw Exception(
        '$name is not set in .env. '
        'Add it and set USE_MOCK_DATA=false to enable live mode.',
      );
    }
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GEMINI SYSTEM INSTRUCTION
// ─────────────────────────────────────────────────────────────────────────────

const String _geminiSystemInstruction = '''
You are an expert in Indian handicrafts and artisan products.

An artisan has described their handmade product in Hindi or a regional Indian language (possibly code-switched with English). Extract the following structured information from their voice transcript and return ONLY a valid JSON object matching the ONDC Beckn Item schema — no markdown, no explanation.

JSON schema:
{
  "id": "item_generated",
  "category_id": "RET16",
  "fulfillment_id": "F1",
  "location_id": "L1",
  "descriptor": {
    "name": "string — SEO-friendly English product title, max 80 chars",
    "short_desc": "string — short description",
    "long_desc": "string — SEO-optimized English description, 150–250 words"
  },
  "price": {
    "currency": "INR",
    "value": "0",
    "maximum_value": "0"
  },
  "quantity": {
    "available": {
      "count": 1
    }
  },
  "@ondc/org/time_to_ship": "PT48H",
  "@ondc/org/returnable": true,
  "@ondc/org/cancellable": true,
  "@ondc/org/available_on_cod": true,
  "@ondc/org/return_window": "P7D",
  "tags": [
    {
      "code": "translation_hi",
      "list": [
        { "code": "name", "value": "Hindi product title" },
        { "code": "long_desc", "value": "Hindi description" }
      ]
    },
    {
      "code": "craft_attributes",
      "list": [
        { "code": "category", "value": "e.g. Terracotta Pottery" },
        { "code": "materials", "value": "comma separated raw materials in English" },
        { "code": "cluster_location", "value": "city/district if mentioned" }
      ]
    },
    {
      "code": "pricing_inputs",
      "list": [
        { "code": "raw_material_cost", "value": "integer or 0 if missing" },
        { "code": "labor_days", "value": "integer or 0 if missing" },
        { "code": "items_produced", "value": "integer or 1 if missing" },
        { "code": "seller_proposed_price", "value": "integer or 0 if missing" }
      ]
    },
    {
      "code": "statutory_info",
      "list": [
        { "code": "country_of_origin", "value": "IND" },
        { "code": "manufacturer_name", "value": "Artisan or brand name, else Unknown" },
        { "code": "net_quantity", "value": "e.g. 1 unit" },
        { "code": "generic_name", "value": "Commodity name" }
      ]
    }
  ]
}

Rules:
- If the artisan mentions a price, it is likely raw_material_cost (not selling price) unless they say "I want to sell for X" (which is seller_proposed_price).
- Return ONLY the JSON object. No markdown fences.
''';
