import '../models/catalog_item.dart';
import '../models/craft_attributes.dart';
import '../models/pricing_corridor.dart';

/// Pre-configured artisan demo payloads for BazaarSetu Karigar AI.
/// Perfectly mapped to the Figma design screens.
class MockData {
  MockData._();

  static final List<CatalogItem> catalogs = [
    terracottaDiya,
    sabaiBasket,
    bluePottery,
    kalamkariDupatta,
    sheeshamCoasters,
    dhokraIdol,
  ];

  // ── 1. Handmade Terracotta Diya (Featured in Screen 1 & Screen 2) ──────────
  static final CatalogItem terracottaDiya = CatalogItem(
    id: 'bazaar_diya_001',
    createdAt: DateTime(2026, 9, 1),
    titleEn: 'Handmade Terracotta Diya',
    titleHi: 'हाथ से बना टेराकोटा दीया',
    descriptionEn:
        'Beautiful handmade terracotta diya crafted using traditional techniques '
        'passed down through generations. Molded with locally sourced clay and dried '
        'under gentle sunlight. Perfect for Diwali, festive celebrations, pooja rituals, '
        'and mindful home decor.',
    descriptionHi:
        'पारंपरिक तकनीकों से बना सुंदर हस्तनिर्मित टेराकोटा दीया। स्थानीय स्तर पर प्राप्त लाल मिट्टी '
        'से ढाला गया और प्राकृतिक धूप में सुखाया गया। दिवाली, उत्सव और पूजा के लिए आदर्श।',
    guildName: 'Pune Rural Guild',
    craftTechnique: 'Hand Wheel & Embossed Carving',
    rating: 4.8,
    reviewCount: 128,
    mrp: 400,
    audioLanguage: 'Marathi',
    audioDurationSeconds: 24,
    studioImagePath:
        'https://images.unsplash.com/photo-1603555501671-8f96b3fce8e4?auto=format&fit=crop&w=800&q=80',
    craftAttributes: const CraftAttributes(
      category: 'Terracotta Pottery • Festive',
      materials: ['Natural Terracotta Clay', 'Earthen Mineral Pigments'],
      laborDays: 2,
      clusterLocation: 'Pune, Maharashtra',
      artisanName: 'Savita Patil',
      dimensions: '180g • 3.5 x 2.0 inches',
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
    status: CatalogStatus.draft,
  );

  // ── 2. Handwoven Sabai Grass Basket ───────────────────────────────────────
  static final CatalogItem sabaiBasket = CatalogItem(
    id: 'bazaar_basket_002',
    createdAt: DateTime(2026, 9, 2),
    titleEn: 'Handwoven Sabai Grass Basket',
    titleHi: 'हाथ से बुनी सबाई घास की टोकरी',
    descriptionEn:
        'Artisanal multipurpose storage basket tightly woven from indigenous wild Sabai grass '
        'by tribal women artisans of Mayurbhanj and West Bengal. Durable, eco-friendly, '
        'and naturally golden-hued.',
    descriptionHi:
        'पश्चिम बंगाल और मयूरभंज की जनजातीय महिला कारीगरों द्वारा सबाई घास से बुनी गई टिकाऊ '
        'और पर्यावरण-अनुकूल टोकरी।',
    guildName: 'Bengal Craft Guild',
    craftTechnique: 'Coil Weaving with Palm Leaf Binds',
    rating: 4.9,
    reviewCount: 86,
    mrp: 1100,
    audioLanguage: 'Bengali',
    audioDurationSeconds: 32,
    studioImagePath:
        'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80',
    craftAttributes: const CraftAttributes(
      category: 'Natural Fiber Weave',
      materials: ['Natural Sabai Grass', 'Cotton Cord', 'Vegetable Dyes'],
      laborDays: 3,
      clusterLocation: 'Bishnupur, West Bengal',
      artisanName: 'Sumitra Soren',
      dimensions: '320g • 10 x 6 inches',
      genericName: 'Grass Basket',
      netQuantity: '1 unit',
      countryOfOrigin: 'IND',
    ),
    pricing: const PricingCorridor(
      rawMaterialCost: 200,
      laborDays: 3,
      dailyWageRate: 450,
      overheadPercent: 0.10,
      floorPrice: 650,
      fairPrice: 850,
      premiumPrice: 1100,
    ),
    status: CatalogStatus.draft,
  );

  // ── 3. Traditional Blue Pottery Set ───────────────────────────────────────
  static final CatalogItem bluePottery = CatalogItem(
    id: 'bazaar_bluepot_003',
    createdAt: DateTime(2026, 9, 3),
    titleEn: 'Traditional Blue Pottery Set',
    titleHi: 'पारंपरिक जयपुरी ब्लू पॉटरी सेट',
    descriptionEn:
        'Iconic Jaipur glazed quartz tableware featuring hand-painted Persian cobalt and turquoise floral motifs. '
        'Prepared without clay using Egyptian quartz powder, fuller’s earth, and glass.',
    descriptionHi:
        'गुलाबी नगर जयपुर की प्रसिद्ध ब्लू पॉटरी जिसमें फारसी कोबाल्ट फूलों के रूपांकन हाथ से चित्रित किए गए हैं।',
    guildName: 'Jaipur Artisan Guild',
    craftTechnique: 'Dough Moulding & Low-Fire Glaze',
    rating: 4.7,
    reviewCount: 142,
    mrp: 1600,
    audioLanguage: 'Hindi',
    audioDurationSeconds: 28,
    studioImagePath:
        'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=800&q=80',
    craftAttributes: const CraftAttributes(
      category: 'Jaipur Blue Pottery',
      materials: ['Quartz Powder', 'Katira Gond', 'Cobalt Oxide Glaze'],
      laborDays: 4,
      clusterLocation: 'Jaipur, Rajasthan',
      artisanName: 'Gopal Kumawat',
      dimensions: '850g • Set of 3 Pieces',
      genericName: 'Decorative Pottery',
      netQuantity: 'Set of 3',
      countryOfOrigin: 'IND',
    ),
    pricing: const PricingCorridor(
      rawMaterialCost: 350,
      laborDays: 4,
      dailyWageRate: 500,
      overheadPercent: 0.10,
      floorPrice: 900,
      fairPrice: 1200,
      premiumPrice: 1600,
    ),
    status: CatalogStatus.draft,
  );

  // ── 4. Kalamkari Handblock Dupatta ─────────────────────────────────────────
  static final CatalogItem kalamkariDupatta = CatalogItem(
    id: 'bazaar_kalamkari_004',
    createdAt: DateTime(2026, 9, 4),
    titleEn: 'Kalamkari Handblock Dupatta',
    titleHi: 'कलमकारी हैंडब्लॉक सिल्क दुपट्टा',
    descriptionEn:
        'Authentic Srikalahasti style hand-block printed dupatta crafted with natural vegetable dyes '
        'on handloom tussar silk. Features tree of life motifs with hand-drawn pen detailing.',
    descriptionHi:
        'प्राकृतिक वनस्पति रंगों और हाथ से नक्काशीदार लकड़ी के ब्लॉकों से तैयार शुद्ध सिल्क कलमकारी दुपट्टा।',
    guildName: 'Andhra Weavers',
    craftTechnique: 'Pen Kalamkari & Mud Resist Dyeing',
    rating: 4.9,
    reviewCount: 64,
    mrp: 1250,
    audioLanguage: 'Telugu',
    audioDurationSeconds: 40,
    studioImagePath:
        'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=800&q=80',
    craftAttributes: const CraftAttributes(
      category: 'Heritage Handloom',
      materials: ['Tussar Silk', 'Alizarin', 'Indigo', 'Myrobalan Extract'],
      laborDays: 6,
      clusterLocation: 'Pedana, Andhra Pradesh',
      artisanName: 'Radha Krishna Rao',
      dimensions: '2.5 meters • 180 grams',
      genericName: 'Silk Dupatta',
      netQuantity: '1 unit',
      countryOfOrigin: 'IND',
    ),
    pricing: const PricingCorridor(
      rawMaterialCost: 400,
      laborDays: 6,
      dailyWageRate: 450,
      overheadPercent: 0.10,
      floorPrice: 750,
      fairPrice: 950,
      premiumPrice: 1250,
    ),
    status: CatalogStatus.draft,
  );

  // ── 5. Hand-carved Sheesham Coasters ───────────────────────────────────────
  static final CatalogItem sheeshamCoasters = CatalogItem(
    id: 'bazaar_sheesham_005',
    createdAt: DateTime(2026, 9, 5),
    titleEn: 'Hand-carved Sheesham Coasters',
    titleHi: 'हस्तनिर्मित शीशम की लकड़ी के कोस्टर',
    descriptionEn:
        'Set of 6 solid Indian rosewood (Sheesham) coasters with fine brass floral inlay, '
        'carved by generational master woodcraftsmen of Saharanpur. Finished with natural beeswax polish.',
    descriptionHi:
        'सहारनपुर के मास्टर कारीगरों द्वारा बारीक पीतल की जड़ाई के साथ हाथ से तराशे गए 6 शीशम के कोस्टर का सेट।',
    guildName: 'Saharanpur Carvers',
    craftTechnique: 'Tarkashi (Brass Wire Inlay)',
    rating: 4.6,
    reviewCount: 52,
    mrp: 600,
    audioLanguage: 'Hindi',
    audioDurationSeconds: 18,
    studioImagePath:
        'https://images.unsplash.com/photo-1590736969955-71cc94801759?auto=format&fit=crop&w=800&q=80',
    craftAttributes: const CraftAttributes(
      category: 'Wood Inlay Craft',
      materials: ['Seasoned Sheesham Wood', 'Pure Brass Wire', 'Beeswax'],
      laborDays: 2,
      clusterLocation: 'Saharanpur, Uttar Pradesh',
      artisanName: 'Mohammad Yusuf',
      dimensions: 'Set of 6 • 4 inches diameter',
      genericName: 'Wooden Coasters',
      netQuantity: 'Set of 6',
      countryOfOrigin: 'IND',
    ),
    pricing: const PricingCorridor(
      rawMaterialCost: 120,
      laborDays: 2,
      dailyWageRate: 400,
      overheadPercent: 0.10,
      floorPrice: 320,
      fairPrice: 450,
      premiumPrice: 600,
    ),
    status: CatalogStatus.draft,
  );

  // ── 6. Brass Dhokra Tribal Idol ───────────────────────────────────────────
  static final CatalogItem dhokraIdol = CatalogItem(
    id: 'bazaar_dhokra_006',
    createdAt: DateTime(2026, 9, 6),
    titleEn: 'Brass Dhokra Tribal Idol',
    titleHi: 'ढोकरा पीतल जनजातीय मूर्ति',
    descriptionEn:
        'Ancient 4,000-year-old lost-wax (cire perdue) hollow-cast brass tribal deity figurine '
        'handcrafted by indigenous metalsmiths of Bastar. Every piece is an original piece of living bronze-age art.',
    descriptionHi:
        'बस्तर के आदिवासी कारीगरों द्वारा प्राचीन लॉस्ट-वैक्स कास्टिंग तकनीक से हस्तनिर्मित ढोकरा पीतल की देवी मूर्ति।',
    guildName: 'Bastar Metal Guild',
    craftTechnique: 'Lost Wax Casting (Cire Perdue)',
    rating: 4.9,
    reviewCount: 110,
    mrp: 2000,
    audioLanguage: 'Chhattisgarhi',
    audioDurationSeconds: 42,
    studioImagePath:
        'https://images.unsplash.com/photo-1582562124811-c09040d0a901?auto=format&fit=crop&w=800&q=80',
    craftAttributes: const CraftAttributes(
      category: 'Dhokra Metal Craft',
      materials: ['Recycled Brass', 'Beeswax', 'Red Clay Core', 'Rice Husk'],
      laborDays: 7,
      clusterLocation: 'Bastar, Chhattisgarh',
      artisanName: 'Mangal Singh Ghadwa',
      dimensions: '620g • 7.5 inches height',
      genericName: 'Brass Figurine',
      netQuantity: '1 unit',
      countryOfOrigin: 'IND',
    ),
    pricing: const PricingCorridor(
      rawMaterialCost: 500,
      laborDays: 7,
      dailyWageRate: 500,
      overheadPercent: 0.10,
      floorPrice: 1200,
      fairPrice: 1550,
      premiumPrice: 2000,
    ),
    status: CatalogStatus.draft,
  );
}
