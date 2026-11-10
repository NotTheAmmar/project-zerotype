import 'craft_attributes.dart';
import 'pricing_corridor.dart';

enum CatalogStatus {
  draft,
  storedLocally,
  published,
}

class CatalogItem {
  final String id;
  final DateTime createdAt;

  // Media
  final String? rawImagePath;
  final String? studioImagePath; // teammate's model output will go here
  final String? audioPath;
  final List<String> galleryImages;

  // Bilingual descriptors
  final String? titleEn;
  final String? titleHi;
  final String? descriptionEn;
  final String? descriptionHi;

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
    this.galleryImages = const [],
    this.titleEn,
    this.titleHi,
    this.descriptionEn,
    this.descriptionHi,
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
    List<String>? galleryImages,
    String? titleEn,
    String? titleHi,
    String? descriptionEn,
    String? descriptionHi,
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
      galleryImages: galleryImages ?? this.galleryImages,
      titleEn: titleEn ?? this.titleEn,
      titleHi: titleHi ?? this.titleHi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'rawImagePath': rawImagePath,
        'studioImagePath': studioImagePath,
        'audioPath': audioPath,
        'galleryImages': galleryImages,
        'titleEn': titleEn,
        'titleHi': titleHi,
        'descriptionEn': descriptionEn,
        'descriptionHi': descriptionHi,
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
        galleryImages: (json['galleryImages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        titleEn: json['titleEn'] as String?,
        titleHi: json['titleHi'] as String?,
        descriptionEn: json['descriptionEn'] as String?,
        descriptionHi: json['descriptionHi'] as String?,
        craftAttributes: json['craftAttributes'] != null
            ? CraftAttributes.fromJson(
                json['craftAttributes'] as Map<String, dynamic>)
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

    final catalogId = json['catalog_id'] as String? ??
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

    final rawImg = json['raw_image_url'] as String? ?? json['rawImagePath'] as String?;
    String? studioImg = json['studio_image_url'] as String? ?? json['studioImagePath'] as String?;
    // Discard any legacy dummy saree fallback image
    if (studioImg != null && studioImg.contains('photo-1610030469983-98e550d6193c')) {
      studioImg = null;
    }
    studioImg ??= rawImg;

    final galleryList = <String>[];
    final rawGallery = json['gallery_images'] ?? json['galleryImages'];
    if (rawGallery is List) {
      for (final g in rawGallery) {
        if (g != null && g.toString().isNotEmpty) {
          final s = g.toString();
          // Filter out dummy saree and primary rawImg duplicate
          if (!s.contains('photo-1610030469983-98e550d6193c') &&
              s != rawImg &&
              !galleryList.contains(s)) {
            galleryList.add(s);
          }
        }
      }
    }

    return CatalogItem(
      id: catalogId,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      titleEn: json['title_en'] as String? ?? json['titleEn'] as String?,
      titleHi: json['title_hi'] as String? ?? json['titleHi'] as String?,
      descriptionEn: json['description_en'] as String? ?? json['descriptionEn'] as String?,
      descriptionHi: json['description_hi'] as String? ?? json['descriptionHi'] as String?,
      rawImagePath: rawImg,
      studioImagePath: studioImg,
      galleryImages: galleryList,
      availableQuantity: (json['available_qty'] as num?)?.toInt() ??
          (json['availableQuantity'] as num?)?.toInt() ??
          1,
      status: CatalogStatus.published,
      craftAttributes: CraftAttributes(
        category: json['craft_category'] as String? ??
            json['category'] as String? ??
            'Handicrafts',
        artisanName: json['artisan_name'] as String? ?? 'BazaarSetu Artisan',
        clusterLocation: json['cluster_name'] as String? ?? 'Chanderi Handloom Cluster',
        materials: materialsList,
        dimensions: json['dimensions'] as String? ?? '',
      ),
      pricing: PricingCorridor(
        floorPrice: floor.round(),
        fairPrice: fair.round(),
        premiumPrice: premium.round(),
        rawMaterialCost: (floor * 0.4).round(),
        laborDays: 1,
        dailyWageRate: 500,
        overheadPercent: 0.10,
        skillMultiplier: 1.0,
      ),
    );
  }
}
