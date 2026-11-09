import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';
import '../models/catalog_item.dart';
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
  final int? spokenPrice;
  final int? spokenQuantity;

  const CatalogProcessResult({
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    this.craftAttributes,
    this.pricing,
    this.studioImagePath,
    this.audioReadbackPath,
    this.spokenPrice,
    this.spokenQuantity,
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
    List<String>? audioPaths,
    String? manualDimensions,
    StageCallback? onStageComplete,
  });

  Future<String> transcribeAudio(String audioPath);

  Future<CatalogItem> updateCatalogWithInstruction({
    required CatalogItem currentItem,
    required String instruction,
  });

  Future<Map<String, dynamic>> publishToOndc({
    required CatalogItem item,
    required PricingCorridor pricing,
    required int availableQuantity,
  });

  Future<bool> unlistFromOndc(String catalogId);

  Future<bool> deleteFromOndc(String catalogId);

  Future<String?> uploadImage(
    String filePath, {
    String imageType = 'studio',
    String? catalogId,
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

  @override
  Future<bool> unlistFromOndc(String catalogId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> deleteFromOndc(String catalogId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<String?> uploadImage(
    String filePath, {
    String imageType = 'studio',
    String? catalogId,
  }) async {
    return 'https://images.unsplash.com/photo-1610030469983-98e550d6193c';
  }

  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    List<String>? audioPaths,
    String? manualDimensions,
    StageCallback? onStageComplete,
  }) async {
    await Future.delayed(AppConstants.mockStage1Delay);
    onStageComplete?.call(0);

    await Future.delayed(AppConstants.mockStage2Delay);
    onStageComplete?.call(1);

    await Future.delayed(AppConstants.mockStage3Delay);
    onStageComplete?.call(2);

    return CatalogProcessResult(
      titleEn: 'Handmade Terracotta Craft',
      titleHi: 'हाथ से बना मिट्टी का दीया',
      descriptionEn:
          'Beautiful handmade craft crafted using traditional techniques passed down through generations. Perfect for home decor and festive celebrations.',
      descriptionHi:
          'कारीगर द्वारा हाथ से तैयार किया गया सुंदर पारंपरिक दीया। प्राकृतिक मिट्टी से बना और धूप में सुखाया गया।',
      craftAttributes: CraftAttributes(
        category: 'Terracotta Pottery',
        materials: const ['Natural Terracotta Clay', 'Earthen Pigments'],
        laborDays: 2,
        clusterLocation: 'Pune Craft Cluster, Maharashtra',
        artisanName: 'Savita Patil',
        dimensions: manualDimensions ?? '5 x 5 inches',
        weight: '180g',
        genericName: 'Earthen Diya',
        netQuantity: '1 unit',
        countryOfOrigin: 'IND',
      ),
      pricing: const PricingCorridor(
        rawMaterialCost: 80,
        laborDays: 2,
        dailyWageRate: 400,
        overheadPercent: 0.10,
        floorPrice: 240,
        fairPrice: 300,
        premiumPrice: 400,
      ),
      studioImagePath: imagePath.isNotEmpty ? imagePath : null,
      audioReadbackPath: null,
      spokenQuantity: 1,
    );
  }

  @override
  Future<String> transcribeAudio(String audioPath) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'कीमत 450 रुपये कर दो और सामग्री में पीतल लिखो';
  }

  @override
  Future<CatalogItem> updateCatalogWithInstruction({
    required CatalogItem currentItem,
    required String instruction,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final numMatch = RegExp(r'\d+').firstMatch(instruction);
    if (numMatch != null) {
      final val = int.tryParse(numMatch.group(0)!);
      if (val != null && val > 0) {
        return currentItem.copyWith(
          pricing: PricingCorridor.compute(
            rawMaterialCost: currentItem.pricing?.rawMaterialCost ?? 100,
            laborDays: currentItem.pricing?.laborDays ?? 1,
            sellerProposedPrice: val,
          ),
        );
      }
    }
    return currentItem;
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

    // 1. Upload raw and studio images to Supabase CDN if stored as local files
    String? finalRawImageUrl = item.rawImagePath?.startsWith('http') == true ? item.rawImagePath : null;
    String? finalStudioImageUrl = item.studioImagePath?.startsWith('http') == true ? item.studioImagePath : null;

    if (item.rawImagePath != null &&
        !item.rawImagePath!.startsWith('http') &&
        File(item.rawImagePath!).existsSync()) {
      try {
        final uploadedRaw = await uploadImage(
          item.rawImagePath!,
          imageType: 'raw',
          catalogId: item.id,
        );
        if (uploadedRaw != null) finalRawImageUrl = uploadedRaw;
      } catch (e) {
        debugPrint('[LiveApiService] Raw image upload skipped: $e');
      }
    }

    if (item.studioImagePath != null &&
        !item.studioImagePath!.startsWith('http') &&
        File(item.studioImagePath!).existsSync()) {
      try {
        final uploadedStudio = await uploadImage(
          item.studioImagePath!,
          imageType: 'studio',
          catalogId: item.id,
        );
        if (uploadedStudio != null) finalStudioImageUrl = uploadedStudio;
      } catch (e) {
        debugPrint('[LiveApiService] Studio image upload skipped: $e');
      }
    }

    // Default fallback image if neither is online
    finalStudioImageUrl ??= 'https://images.unsplash.com/photo-1610030469983-98e550d6193c';

    final body = {
      'catalog_id': item.id,
      'artisan_name': item.craftAttributes?.artisanName ?? 'BazaarSetu Artisan',
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
      'raw_image_url': finalRawImageUrl,
      'studio_image_url': finalStudioImageUrl,
      'gallery_images': <String>[],
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
  Future<String?> uploadImage(
    String filePath, {
    String imageType = 'studio',
    String? catalogId,
  }) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final uri = Uri.parse('${AppConstants.bppBackendUrl}/api/v1/bpp/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['bypass-tunnel-reminder'] = 'true';
      if (catalogId != null) {
        request.fields['catalog_id'] = catalogId;
      }
      request.fields['image_type'] = imageType;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('[LiveApiService] uploadImage failed: $e');
    }
    return null;
  }

  @override
  Future<bool> unlistFromOndc(String catalogId) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.bppBackendUrl}/api/v1/bpp/listings/$catalogId/unlist',
      );
      final response = await http
          .post(uri, headers: {'bypass-tunnel-reminder': 'true'})
          .timeout(AppConstants.apiTimeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[LiveApiService] unlistFromOndc failed: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteFromOndc(String catalogId) async {
    try {
      final uri = Uri.parse(
        '${AppConstants.bppBackendUrl}/api/v1/bpp/listings/$catalogId',
      );
      final response = await http
          .delete(uri, headers: {'bypass-tunnel-reminder': 'true'})
          .timeout(AppConstants.apiTimeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[LiveApiService] deleteFromOndc failed: $e');
      return false;
    }
  }

  @override
  Future<CatalogProcessResult> processCatalog({
    required String imagePath,
    required String audioPath,
    List<String>? audioPaths,
    String? manualDimensions,
    StageCallback? onStageComplete,
  }) async {
    return _processViaBhashini(
      imagePath: imagePath,
      audioPath: audioPath,
      audioPaths: audioPaths,
      manualDimensions: manualDimensions,
      onStageComplete: onStageComplete,
    );
  }

  @override
  Future<String> transcribeAudio(String audioPath) async {
    if (audioPath.isEmpty || !File(audioPath).existsSync()) return '';
    String transcript = '';
    if (AppConstants.voicePipeline == 'groq' ||
        (AppConstants.voicePipeline == 'auto' && AppConstants.groqApiKey.isNotEmpty)) {
      try {
        transcript = await _transcribeWithGroqWhisper(audioPath);
        if (transcript.isNotEmpty) return transcript;
      } catch (e) {
        debugPrint('[transcribeAudio] Whisper failed: $e');
      }
    }
    if (AppConstants.bhashiniApiKey.isNotEmpty) {
      try {
        transcript = await _bhashiniService.transcribe(audioPath);
        if (transcript.isNotEmpty) return transcript;
      } catch (e) {
        debugPrint('[transcribeAudio] Bhashini failed: $e');
      }
    }
    return transcript;
  }

  @override
  Future<CatalogItem> updateCatalogWithInstruction({
    required CatalogItem currentItem,
    required String instruction,
  }) async {
    if (AppConstants.groqApiKey.isNotEmpty) {
      try {
        return await _updateWithQwen(currentItem, instruction);
      } catch (e) {
        debugPrint('[LiveApiService] Qwen voice update failed: $e');
      }
    }
    return _applyHeuristicUpdate(currentItem, instruction);
  }

  Future<CatalogItem> _updateWithQwen(
    CatalogItem currentItem,
    String instruction,
  ) async {
    final apiKey = AppConstants.groqApiKey;
    String model = AppConstants.qwenModel;
    final uri = Uri.parse(AppConstants.qwenApiUrl);

    if (AppConstants.qwenApiUrl.contains('groq.com')) {
      if (model.isEmpty ||
          model == 'qwen-2.5-32b-it' ||
          model == 'qwen-2.5-7b-instruct' ||
          model == 'qwen-2.5-32b') {
        model = 'qwen/qwen3.8-27b';
      }
    }

    final currentDict = {
      'title_en': currentItem.titleEn ?? '',
      'title_hi': currentItem.titleHi ?? '',
      'category': currentItem.craftAttributes?.category ?? '',
      'materials': currentItem.craftAttributes?.materials ?? [],
      'labor_days': currentItem.craftAttributes?.laborDays ?? 1,
      'raw_material_cost': currentItem.pricing?.rawMaterialCost ?? 100,
      'selling_price': currentItem.pricing?.fairPrice ?? 350,
      'dimensions': currentItem.craftAttributes?.dimensions ?? '',
      'weight': currentItem.craftAttributes?.weight ?? '',
      'net_quantity': currentItem.craftAttributes?.netQuantity ?? '1 unit',
      'description_en': currentItem.descriptionEn ?? '',
      'description_hi': currentItem.descriptionHi ?? '',
    };

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    final payload = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': '''You are an expert assistant for Indian artisans updating their craft catalog on BazaarSetu (ONDC network).
The artisan provides instructions in Hindi, Hinglish, or English to update their product listing.
You are given the current listing data as JSON and the artisan's update command.
Update ONLY the fields mentioned or implied by the artisan. Keep all other fields unchanged.
Always output pure valid JSON with these keys:
{
  "title_en": "string",
  "title_hi": "string",
  "category": "string",
  "materials": ["string"],
  "labor_days": number,
  "raw_material_cost": number,
  "selling_price": number,
  "dimensions": "string",
  "weight": "string",
  "net_quantity": "string",
  "description_en": "string",
  "description_hi": "string"
}'''
        },
        {
          'role': 'user',
          'content': '''Current listing:
${jsonEncode(currentDict)}

Artisan update instruction:
"$instruction"'''
        }
      ],
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
    };

    http.Response response = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(AppConstants.apiTimeout);

    if (response.statusCode == 404 && model != 'qwen/qwen3.8-27b') {
      payload['model'] = 'qwen/qwen3.8-27b';
      response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(AppConstants.apiTimeout);
    }

    if (response.statusCode != 200) {
      throw Exception('Qwen update failed (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Qwen returned empty choices.');
    }
    final content = choices.first['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Qwen message content was empty.');
    }

    final cleanJson = content
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    final j = jsonDecode(cleanJson) as Map<String, dynamic>;

    final updatedMaterials = (j['materials'] is List)
        ? (j['materials'] as List).map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : currentItem.craftAttributes?.materials ?? <String>[];

    final updatedLaborDays = _parseInt(j['labor_days']) ?? currentItem.craftAttributes?.laborDays ?? 1;
    final updatedRawCost = _parseInt(j['raw_material_cost']) ?? currentItem.pricing?.rawMaterialCost ?? 100;
    final updatedSellingPrice = _parseInt(j['selling_price']) ?? currentItem.pricing?.fairPrice ?? 350;

    final updatedPricing = PricingCorridor.compute(
      rawMaterialCost: updatedRawCost,
      laborDays: updatedLaborDays,
      sellerProposedPrice: updatedSellingPrice,
    );

    return currentItem.copyWith(
      titleEn: j['title_en']?.toString() ?? currentItem.titleEn,
      titleHi: j['title_hi']?.toString() ?? currentItem.titleHi,
      descriptionEn: j['description_en']?.toString() ?? currentItem.descriptionEn,
      descriptionHi: j['description_hi']?.toString() ?? currentItem.descriptionHi,
      craftAttributes: (currentItem.craftAttributes ?? const CraftAttributes()).copyWith(
        category: j['category']?.toString() ?? currentItem.craftAttributes?.category,
        materials: updatedMaterials.isNotEmpty ? updatedMaterials : currentItem.craftAttributes?.materials,
        laborDays: updatedLaborDays,
        dimensions: j['dimensions']?.toString() ?? currentItem.craftAttributes?.dimensions,
        weight: j['weight']?.toString() ?? currentItem.craftAttributes?.weight,
        netQuantity: j['net_quantity']?.toString() ?? currentItem.craftAttributes?.netQuantity,
      ),
      pricing: updatedPricing,
    );
  }

  CatalogItem _applyHeuristicUpdate(CatalogItem currentItem, String instruction) {
    final lower = instruction.toLowerCase();
    int? newPrice;
    final numMatch = RegExp(r'\d+').firstMatch(instruction);
    if (numMatch != null &&
        (lower.contains('price') ||
            lower.contains('कीमत') ||
            lower.contains('रुपये') ||
            lower.contains('₹') ||
            lower.contains('रुपया'))) {
      newPrice = int.tryParse(numMatch.group(0)!);
    }

    PricingCorridor? newPricing = currentItem.pricing;
    if (newPrice != null && newPrice > 0) {
      newPricing = PricingCorridor.compute(
        rawMaterialCost: currentItem.pricing?.rawMaterialCost ?? 100,
        laborDays: currentItem.pricing?.laborDays ?? 1,
        sellerProposedPrice: newPrice,
      );
    }

    return currentItem.copyWith(pricing: newPricing);
  }

  // ── Bhashini Cloud (direct client-side calls, no backend) ────────

  final BhashiniService _bhashiniService = BhashiniService();

  Future<CatalogProcessResult> _processViaBhashini({
    required String imagePath,
    required String audioPath,
    List<String>? audioPaths,
    String? manualDimensions,
    StageCallback? onStageComplete,
  }) async {
    // Stage 0: image processing
    onStageComplete?.call(0);

    final List<String> segments = [];

    // Step 1: Transcribe multi-step audios or single audioPath
    final audiosToTranscribe = (audioPaths != null && audioPaths.isNotEmpty)
        ? audioPaths
        : (audioPath.isNotEmpty ? [audioPath] : <String>[]);

    for (int i = 0; i < audiosToTranscribe.length; i++) {
      final p = audiosToTranscribe[i];
      if (p.isNotEmpty && File(p).existsSync()) {
        final text = await transcribeAudio(p);
        if (text.isNotEmpty) {
          segments.add('Step ${i + 1}: $text');
        }
      }
    }

    if (manualDimensions != null && manualDimensions.isNotEmpty) {
      segments.add('उत्पाद माप एवं मात्रा / Dimensions & Quantity: $manualDimensions');
    }

    String transcript = segments.join('. ').trim();
    if (transcript.isEmpty) {
      transcript = 'Handmade artisan craft with natural raw materials, traditional skills, and delicate craftwork.';
    }

    // Stage 1: voice transcription done
    onStageComplete?.call(1);

    // Step 2: Extract structured catalog with Qwen or Gemini
    final useQwen = AppConstants.aiExtractionProvider.contains('qwen');

    if (useQwen && AppConstants.groqApiKey.isNotEmpty) {
      try {
        final extracted = await _extractWithQwen(transcript);
        onStageComplete?.call(2);
        return resultFromQwenExtraction(extracted, descHiFallback: transcript);
      } catch (e) {
        debugPrint('[AI] Qwen extraction error: $e');
      }
    }

    // Fallback: Safe default draft result so progress is never lost
    onStageComplete?.call(2);
    return CatalogProcessResult(
      titleEn: 'Handcrafted Artisan Item',
      titleHi: 'हस्तनिर्मित शिल्प उत्पाद',
      descriptionEn: 'Authentic handcrafted product made with traditional techniques and generational artisan skill.',
      descriptionHi: transcript.isNotEmpty ? transcript : 'कुशल कारीगर द्वारा पारंपरिक विधि से हस्तनिर्मित उत्कृष्ट उत्पाद।',
      craftAttributes: const CraftAttributes(
        category: 'Handmade Craft',
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
      studioImagePath: imagePath,
      spokenQuantity: 1,
    );
  }

  Future<String> _transcribeWithGroqWhisper(String audioPath) async {
    final apiKey = AppConstants.groqApiKey;
    if (apiKey.isEmpty) throw Exception('GROQ_API_KEY is not configured');

    final uri = Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = 'whisper-large-v3-turbo';
    request.fields['response_format'] = 'json';

    final file = await http.MultipartFile.fromPath('file', audioPath);
    request.files.add(file);

    final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Groq Whisper failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['text'] as String? ?? '';
    return text.trim();
  }

  Future<Map<String, dynamic>> _extractWithQwen(String transcript) async {
    final apiKey = AppConstants.groqApiKey;
    String model = AppConstants.qwenModel;
    final uri = Uri.parse(AppConstants.qwenApiUrl);

    // Auto-map model if running on Groq
    if (AppConstants.qwenApiUrl.contains('groq.com')) {
      if (model.isEmpty ||
          model == 'qwen-2.5-32b-it' ||
          model == 'qwen-2.5-7b-instruct' ||
          model == 'qwen-2.5-32b') {
        model = 'qwen/qwen3.8-27b';
      }
    }

    final headers = {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };

    final payload = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content': _qwenSystemInstruction,
        },
        {
          'role': 'user',
          'content': transcript.isNotEmpty
              ? transcript
              : 'Handmade artisan craft with natural raw materials and traditional technique.',
        }
      ],
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
    };

    http.Response response = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(AppConstants.apiTimeout);

    // If requested model was not found (404), fallback to active Groq model
    if (response.statusCode == 404 && model != 'qwen/qwen3.8-27b') {
      debugPrint('[Qwen] Model $model not found, retrying with qwen/qwen3.8-27b');
      payload['model'] = 'qwen/qwen3.8-27b';
      response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(AppConstants.apiTimeout);
    }

    if (response.statusCode != 200) {
      throw Exception('Qwen extraction failed (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Qwen returned empty choices.');
    }
    final content = choices.first['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Qwen message content was empty.');
    }

    final cleanJson = content
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();

    return jsonDecode(cleanJson) as Map<String, dynamic>;
  }

  static CatalogProcessResult resultFromQwenExtraction(
    Map<String, dynamic> j, {
    required String descHiFallback,
  }) {
    final commodity = j['commodity_name']?.toString();
    final craftType = j['craft_type']?.toString();
    final material = j['material']?.toString();
    final workType = j['work_type']?.toString();
    final netQty = j['net_quantity']?.toString() ?? '1 unit';
    final location = j['cluster_location']?.toString() ?? 'Pune Rural Cluster, Maharashtra';

    final pricingInputs = j['pricing_inputs'] is Map ? (j['pricing_inputs'] as Map) : {};
    final laborDays = _parseInt(pricingInputs['labor_days']) ?? 1;
    final rawCost = _parseInt(pricingInputs['raw_material_cost']) ?? 100;

    final spokenPrice = _parseInt(j['spoken_price']);
    final spokenQty = _parseInt(j['spoken_quantity']);
    final dimensions = j['dimensions']?.toString();
    final weight = j['weight']?.toString();

    final pricing = PricingCorridor.compute(
      rawMaterialCost: rawCost,
      laborDays: laborDays,
      itemsProduced: (spokenQty != null && spokenQty > 0) ? spokenQty : 1,
      sellerProposedPrice: spokenPrice ?? 0,
    );

    final titleEn = j['title_en']?.toString() ??
        (craftType != null && commodity != null ? '$craftType $commodity' : 'Handmade $commodity');
    final titleHi = j['title_hi']?.toString() ?? 'हस्तनिर्मित उत्पाद';
    final descEn = j['description_en']?.toString() ??
        'Authentic handcrafted product made with traditional techniques.${workType != null ? " Technique: $workType." : ""} Pure $material, delicately crafted by generational artisans.';
    final descHi = j['description_hi']?.toString() ??
        (descHiFallback.isNotEmpty ? descHiFallback : 'पारंपरिक कारीगरी द्वारा निर्मित सुंदर हस्तशिल्प उत्पाद।');

    final materialsList = <String>[];
    if (material != null && material.isNotEmpty) {
      materialsList.addAll(material.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (materialsList.isEmpty) {
      materialsList.add('Natural Clay & Earth');
    }

    return CatalogProcessResult(
      titleEn: titleEn,
      titleHi: titleHi,
      descriptionEn: descEn,
      descriptionHi: descHi,
      craftAttributes: CraftAttributes(
        category: craftType ?? 'Terracotta Pottery',
        materials: materialsList,
        laborDays: laborDays,
        clusterLocation: location,
        artisanName: 'Savita Patil',
        countryOfOrigin: 'IND',
        dimensions: dimensions,
        weight: weight,
        netQuantity: netQty,
        genericName: commodity ?? 'Diya',
        timeToShip: 'PT24H',
        returnWindow: 'P7D',
        returnable: true,
        cancellable: true,
        availableOnCod: true,
      ),
      pricing: pricing,
      spokenPrice: spokenPrice,
      spokenQuantity: spokenQty,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static int? parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }

  static int? _parseInt(dynamic v) => parseInt(v);
}

// ─────────────────────────────────────────────────────────────────────────────
// QWEN SYSTEM INSTRUCTION (Strict Modality Partitioning)
// ─────────────────────────────────────────────────────────────────────────────

const String _qwenSystemInstruction = '''
You are an expert Indian artisan commerce assistant for BazaarSetu.
Given an English-translated voice transcript spoken by a rural artisan, craftsman, or local seller describing their product, extract the structured attributes and return ONLY a valid JSON object matching the exact schema below. Do not output markdown fences or explanatory text.

Schema:
{
  "commodity_name": "string (e.g. Diya, Saree, Kurta, Basket, Idol, Pickle, Spice)",
  "craft_type": "string (e.g. Terracotta Pottery, Handloom Silk, Dokra Metalcraft, Woodcarving)",
  "material": "string (comma-separated, e.g. Terracotta Clay, Pure Silk, Brass, Teakwood)",
  "work_type": "string or null (e.g. Hand-carved, Handwoven, Lost-wax cast, Embroidered)",
  "net_quantity": "string (e.g. 1 unit, 500g, 6.2 meters, or 1 unit by default)",
  "cluster_location": "string or null (e.g. Pune, Chanderi, Bastar, Jaipur if mentioned)",
  "dimensions": "string or null (e.g. 5x5 inches, 10x6 inches, 2.5 meters, or null if unknown)",
  "weight": "string or null (e.g. 250g, 1.2kg, 500 grams, or null if unknown)",
  "title_en": "SEO-friendly attractive product title in English (max 70 chars)",
  "title_hi": "Simple, natural, conversational Hindi product title in Devanagari script (use everyday words, NOT heavy or overly formal Sanskritized Hindi)",
  "description_en": "Engaging artisan storytelling description in English (80-120 words)",
  "description_hi": "Warm, natural artisan storytelling description in simple conversational Hindi (Devanagari). Use everyday spoken words, NOT formal or archaic Sanskritized terms.",
  "pricing_inputs": {
    "raw_material_cost": "integer or null (cost of raw materials mentioned by seller)",
    "labor_days": "integer or null (days or time taken to craft this item)"
  },
  "spoken_price": "integer or null (if seller explicitly states selling price, e.g. 350)",
  "spoken_quantity": "integer or null (if seller explicitly states count in stock, e.g. 5)"
}

Rules:
1. Extract numerical values as integers (e.g. 350, not "₹350").
2. If the seller does not state a price or quantity, return null for spoken_price and spoken_quantity.
3. Return ONLY the JSON object.
''';


