import 'craft_attributes.dart';
import 'pricing_corridor.dart';

enum CatalogStatus { draft, storedLocally, published }

class CatalogItem {
  final String id;
  final DateTime createdAt;

  // Media
  final String? rawImagePath;
  final String? studioImagePath; // teammate's model output will go here
  final String? audioPath;
  final List<String> rawGalleryImages;
  final List<String> galleryImages;

  // Bilingual / Multilingual descriptors
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;
  final Map<String, String> localizedTitles;
  final Map<String, String> localizedDescriptions;

  // Craft attributes
  final CraftAttributes? craftAttributes;

  // Pricing
  final PricingCorridor? pricing;

  // Inventory
  final int availableQuantity;

  // TTS readback URL/path (from Bhashini or flutter_tts)
  final String? audioReadbackPath;

  // Status
  final CatalogStatus status;

  // UI / Figma Display Enrichments
  final double rating;
  final int reviewCount;
  final int? mrp;
  final String? guildName;
  final String? craftTechnique;
  final String audioLanguage;
  final int audioDurationSeconds;

  const CatalogItem({
    required this.id,
    required this.createdAt,
    this.rawImagePath,
    this.studioImagePath,
    this.audioPath,
    this.rawGalleryImages = const [],
    this.galleryImages = const [],
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
    this.localizedTitles = const {},
    this.localizedDescriptions = const {},
    this.craftAttributes,
    this.pricing,
    this.availableQuantity = 1,
    this.audioReadbackPath,
    this.status = CatalogStatus.draft,
    this.rating = 4.8,
    this.reviewCount = 128,
    this.mrp,
    this.guildName,
    this.craftTechnique,
    this.audioLanguage = 'Hindi',
    this.audioDurationSeconds = 24,
  });

  CatalogItem copyWith({
    String? id,
    DateTime? createdAt,
    String? rawImagePath,
    String? studioImagePath,
    String? audioPath,
    List<String>? rawGalleryImages,
    List<String>? galleryImages,
    String? titleEn,
    String? titleHi,
    String? descriptionEn,
    String? descriptionHi,
    Map<String, String>? localizedTitles,
    Map<String, String>? localizedDescriptions,
    CraftAttributes? craftAttributes,
    PricingCorridor? pricing,
    int? availableQuantity,
    String? audioReadbackPath,
    CatalogStatus? status,
    double? rating,
    int? reviewCount,
    int? mrp,
    String? guildName,
    String? craftTechnique,
    String? audioLanguage,
    int? audioDurationSeconds,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      rawImagePath: rawImagePath ?? this.rawImagePath,
      studioImagePath: studioImagePath ?? this.studioImagePath,
      audioPath: audioPath ?? this.audioPath,
      rawGalleryImages: rawGalleryImages ?? this.rawGalleryImages,
      galleryImages: galleryImages ?? this.galleryImages,
      titleEn: titleEn ?? this.titleEn,
      titleHi: titleHi ?? this.titleHi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
      localizedTitles: localizedTitles ?? this.localizedTitles,
      localizedDescriptions:
          localizedDescriptions ?? this.localizedDescriptions,
      craftAttributes: craftAttributes ?? this.craftAttributes,
      pricing: pricing ?? this.pricing,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      audioReadbackPath: audioReadbackPath ?? this.audioReadbackPath,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      mrp: mrp ?? this.mrp,
      guildName: guildName ?? this.guildName,
      craftTechnique: craftTechnique ?? this.craftTechnique,
      audioLanguage: audioLanguage ?? this.audioLanguage,
      audioDurationSeconds: audioDurationSeconds ?? this.audioDurationSeconds,
    );
  }

  String? titleFor(String code) {
    final t = localizedTitles[code]?.trim();
    if (t != null && t.isNotEmpty) return t;
    if (code == 'en') return titleEn;
    if (code == 'hi') return titleHi;
    return null;
  }

  String? descriptionFor(String code) {
    final d = localizedDescriptions[code]?.trim();
    if (d != null && d.isNotEmpty) return d;
    if (code == 'en') return descriptionEn;
    if (code == 'hi') return descriptionHi;
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'rawImagePath': rawImagePath,
    'studioImagePath': studioImagePath,
    'audioPath': audioPath,
    'rawGalleryImages': rawGalleryImages,
    'galleryImages': galleryImages,
    'titleEn': titleEn,
    'titleHi': titleHi,
    'descriptionEn': descriptionEn,
    'descriptionHi': descriptionHi,
    'localizedTitles': localizedTitles,
    'localizedDescriptions': localizedDescriptions,
    'craftAttributes': craftAttributes?.toJson(),
    'pricing': pricing?.toJson(),
    'availableQuantity': availableQuantity,
    'audioReadbackPath': audioReadbackPath,
    'status': status.name,
    'rating': rating,
    'reviewCount': reviewCount,
    'mrp': mrp,
    'guildName': guildName,
    'craftTechnique': craftTechnique,
    'audioLanguage': audioLanguage,
    'audioDurationSeconds': audioDurationSeconds,
  };

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    rawImagePath: json['rawImagePath'] as String?,
    studioImagePath: json['studioImagePath'] as String?,
    audioPath: json['audioPath'] as String?,
    rawGalleryImages:
        (json['rawGalleryImages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    galleryImages:
        (json['galleryImages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    titleEn: json['titleEn'] as String?,
    titleHi: json['titleHi'] as String?,
    descriptionEn: json['descriptionEn'] as String?,
    descriptionHi: json['descriptionHi'] as String?,
    localizedTitles:
        (json['localizedTitles'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        const {},
    localizedDescriptions:
        (json['localizedDescriptions'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        const {},
    craftAttributes: json['craftAttributes'] != null
        ? CraftAttributes.fromJson(
            json['craftAttributes'] as Map<String, dynamic>,
          )
        : null,
    pricing: json['pricing'] != null
        ? PricingCorridor.fromJson(json['pricing'] as Map<String, dynamic>)
        : null,
    availableQuantity: json['availableQuantity'] as int? ?? 1,
    audioReadbackPath: json['audioReadbackPath'] as String?,
    status: CatalogStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => CatalogStatus.draft,
    ),
    rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    reviewCount: json['reviewCount'] as int? ?? 128,
    mrp: json['mrp'] as int?,
    guildName: json['guildName'] as String?,
    craftTechnique: json['craftTechnique'] as String?,
    audioLanguage: json['audioLanguage'] as String? ?? 'Hindi',
    audioDurationSeconds: json['audioDurationSeconds'] as int? ?? 24,
  );

  factory CatalogItem.fromBppListing(Map<String, dynamic> raw) {
    final payloadMap = raw['payload'] is Map<String, dynamic>
        ? raw['payload'] as Map<String, dynamic>
        : null;
    final json = payloadMap != null ? {...raw, ...payloadMap} : raw;

    final catalogId =
        json['catalog_id'] as String? ??
        json['id'] as String? ??
        'craft_${DateTime.now().millisecondsSinceEpoch}';

    final floor = (json['floor_price'] as num?)?.toDouble() ?? 0.0;
    final fair = (json['fair_price'] as num?)?.toDouble() ?? 0.0;
    final premium = (json['premium_price'] as num?)?.toDouble() ?? 0.0;

    final materialsList = <String>[];
    if (json['materials'] is List) {
      for (final m in json['materials'] as List) {
        if (m != null) materialsList.add(m.toString());
      }
    }

    final rawImg =
        json['raw_image_url'] as String? ?? json['rawImagePath'] as String?;
    String? studioImg =
        json['studio_image_url'] as String? ??
        json['studioImagePath'] as String?;
    // Discard any legacy dummy saree fallback image, raw bucket URL, or raw duplicate
    if (studioImg != null &&
        (studioImg.isEmpty ||
            studioImg.contains('photo-1610030469983-98e550d6193c') ||
            studioImg.contains('/raw-craft-images/') ||
            studioImg == rawImg)) {
      studioImg = null;
    }

    final rawGalleryList = <String>[];
    final rawGallerySrc =
        json['raw_gallery_images'] ?? json['rawGalleryImages'];
    if (rawGallerySrc is List) {
      for (final g in rawGallerySrc) {
        if (g != null && g.toString().isNotEmpty) {
          final s = g.toString();
          if (!s.contains('photo-1610030469983-98e550d6193c') &&
              s != rawImg &&
              !rawGalleryList.contains(s)) {
            rawGalleryList.add(s);
          }
        }
      }
    }

    final galleryList = <String>[];
    final rawGallery = json['gallery_images'] ?? json['galleryImages'];
    if (rawGallery is List) {
      for (final g in rawGallery) {
        if (g != null && g.toString().isNotEmpty) {
          final s = g.toString();
          if (s.contains('photo-1610030469983-98e550d6193c') || s == rawImg) {
            continue;
          }
          final looksLikeRaw =
              s.contains('/raw-craft-images/') ||
              s.contains('_raw.') ||
              s.contains('_raw_') ||
              !s.startsWith('http');
          if (looksLikeRaw) {
            if (!rawGalleryList.contains(s)) rawGalleryList.add(s);
          } else if (!galleryList.contains(s)) {
            galleryList.add(s);
          }
        }
      }
    }

    final statusStr = (json['status'] as String?)?.toUpperCase();
    final restoredStatus = (statusStr == 'DRAFT' || statusStr == 'UNLISTED')
        ? CatalogStatus.draft
        : CatalogStatus.published;

    final locTitles =
        (json['localized_titles'] as Map<String, dynamic>? ??
                json['localizedTitles'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())) ??
        const <String, String>{};
    final locDescs =
        (json['localized_descriptions'] as Map<String, dynamic>? ??
                json['localizedDescriptions'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v.toString())) ??
        const <String, String>{};

    final rawCost = (json['raw_material_cost'] as num?)?.round();
    final laborDays = (json['labor_days'] as num?)?.toInt() ?? 1;

    return CatalogItem(
      id: catalogId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      titleEn: json['title_en'] as String? ?? json['titleEn'] as String?,
      titleHi: json['title_hi'] as String? ?? json['titleHi'] as String?,
      descriptionEn:
          json['description_en'] as String? ?? json['descriptionEn'] as String?,
      descriptionHi:
          json['description_hi'] as String? ?? json['descriptionHi'] as String?,
      localizedTitles: locTitles,
      localizedDescriptions: locDescs,
      rawImagePath: rawImg,
      studioImagePath: studioImg,
      rawGalleryImages: rawGalleryList,
      galleryImages: galleryList,
      availableQuantity:
          (json['available_qty'] as num?)?.toInt() ??
          (json['availableQuantity'] as num?)?.toInt() ??
          1,
      status: restoredStatus,
      craftTechnique:
          json['craft_technique'] as String? ?? json['craftTechnique'] as String?,
      craftAttributes: CraftAttributes(
        category:
            json['craft_category'] as String? ??
            json['category'] as String? ??
            'Handicrafts',
        artisanName: json['artisan_name'] as String? ?? 'BazaarSetu Artisan',
        clusterLocation:
            json['cluster_name'] as String? ?? 'Chanderi Handloom Cluster',
        materials: materialsList,
        dimensions: json['dimensions'] as String? ?? '',
        weight: json['weight'] as String?,
        netQuantity: json['net_quantity'] as String? ?? '1 unit',
        laborDays: laborDays,
      ),
      pricing: PricingCorridor(
        floorPrice: floor.round(),
        fairPrice: fair.round(),
        premiumPrice: premium.round(),
        rawMaterialCost: rawCost ?? (floor * 0.4).round(),
        laborDays: laborDays,
        dailyWageRate: 500,
        overheadPercent: 0.10,
        skillMultiplier: 1.0,
      ),
    );
  }
}
