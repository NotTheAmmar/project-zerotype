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
}
