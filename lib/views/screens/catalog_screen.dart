import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/catalog_item.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _quantity = 1;
  int _selectedThumb = 0;
  bool _isPlayingAudio = false;
  bool _isPublishing = false;
  int? _overridePrice;
  String _selectedTier = 'fair'; // 'floor' | 'fair' | 'premium'

  final List<String> _thumbnails = [
    'https://images.unsplash.com/photo-1603555501671-8f96b3fce8e4?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1603555501371-55110eb2df43?auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
  ];

  @override
  Widget build(BuildContext context) {
    final catalogCtrl = context.watch<CatalogController>();
    final item = catalogCtrl.item;

    if (item == null) {
      return Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: _buildAppBar(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Craft Selected',
                  style: AppTextStyles.serifTitle(),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select a craft from your listings or create a new craft listing.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _navigateBackToExplore(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Back to Crafts'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final floorPrice = item.pricing?.floorPrice ?? 200;
    final baseFairPrice = item.pricing?.fairPrice ?? 300;
    final premiumPrice = item.pricing?.premiumPrice ?? 450;

    final selectedTierPrice = _selectedTier == 'floor'
        ? floorPrice
        : (_selectedTier == 'premium' ? premiumPrice : baseFairPrice);

    final activePrice = _overridePrice ?? selectedTierPrice;
    final mrp = (activePrice * 1.25).round();
    final discountPercent = mrp > activePrice && mrp > 0
        ? (((mrp - activePrice) / mrp) * 100).round()
        : 20;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateBackToExplore(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: _buildAppBar(context),
        body: SafeArea(
        child: Column(
          children: [
            // ── Artisan Preview Ribbon ────────────────────────────────────
            _buildArtisanRibbon(),

            // ── Scrollable Content ────────────────────────────────────────
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Hero Image Section
                        _buildImageSection(item),
                        const SizedBox(height: 14),

                        // 2. Title & Tactile Pricing Card
                        _buildTitleAndPriceCard(
                          item,
                          activePrice,
                          floorPrice,
                          baseFairPrice,
                          premiumPrice,
                          mrp,
                          discountPercent,
                        ),
                        const SizedBox(height: 14),

                        // 3. About this craft Card
                        _buildAboutCraftCard(item),
                        const SizedBox(height: 14),

                        // 4. Meet the Artisan Card
                        _buildMeetArtisanCard(item),
                        const SizedBox(height: 14),

                        // 5. Product Specifications Card
                        _buildSpecificationsCard(item),
                        const SizedBox(height: 14),

                        // 6. Fulfilment & Delivery Card
                        _buildDeliveryCard(),
                        const SizedBox(height: 14),

                        // 7. Buyer Interface Simulation
                        _buildBuyerSimulation(activePrice),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Sticky Bottom Action Bar ──────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _buildBottomActionBar(context, catalogCtrl, item),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _navigateBackToExplore(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.explore,
      (route) => false,
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => _navigateBackToExplore(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.secondaryTerracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.temple_hindu_rounded,
              color: AppColors.secondaryTerracotta,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Product Detail',
            style: AppTextStyles.label.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Artisan Ribbon ─────────────────────────────────────────────────────────
  Widget _buildArtisanRibbon() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF8E4D32),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.tertiarySaffron,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Artisan Preview Mode • This is how customers see your craft on BazaarSetu',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Draft v1.2',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Hero Image Section ──────────────────────────────────────────────────
  Widget _buildImageSection(CatalogItem item) {
    final imagePath = item.studioImagePath ?? item.rawImagePath;
    final isLocal = imagePath != null && !imagePath.startsWith('http');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Main Image with Dynamic AspectRatio
          AspectRatio(
            aspectRatio: 1.25,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isLocal && File(imagePath).existsSync())
                    Image.file(File(imagePath), fit: BoxFit.cover)
                  else if (imagePath != null && imagePath.startsWith('http'))
                    Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceContainer,
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 40, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Image.network(
                      _thumbnails[_selectedThumb % _thumbnails.length],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceContainer,
                        child: const Center(
                          child: Icon(Icons.image_outlined, size: 40, color: AppColors.textSecondary),
                        ),
                      ),
                    ),

                // Top Left Badges: Handmade + AI-Listed
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF674000).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.handyman_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Handmade',
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'AI-Listed',
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Right Heart Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.secondaryTerracotta,
                      size: 18,
                    ),
                  ),
                ),

                // Bottom Right Counter Chip
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedThumb + 1}/4',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

          // Thumbnail Row
          Row(
            children: [
              ...List.generate(_thumbnails.length, (i) {
                final isSelected = _selectedThumb == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedThumb = i),
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryTeal : AppColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      _thumbnails[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),

              // 360 View Button
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBECE5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondaryTerracotta.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.view_in_ar_rounded,
                        color: AppColors.secondaryTerracotta,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '360° View',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondaryTerracotta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Title & Tactile Pricing Card ───────────────────────────────────────
  Widget _buildTitleAndPriceCard(
    CatalogItem item,
    int activePrice,
    int floorPrice,
    int baseFairPrice,
    int premiumPrice,
    int mrp,
    int discountPercent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Breadcrumb + Edit Pencil
          Row(
            children: [
              Expanded(
                child: Text(
                  item.craftAttributes?.category?.toUpperCase() ??
                      'TERRACOTTA POTTERY • FESTIVE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondaryTerracotta,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _openVoiceEditDrawer(context, activePrice),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Edit by voice or values',
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title
          Text(
            item.titleEn ?? 'Handmade Terracotta Diya',
            style: AppTextStyles.serifHeading(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),

          // Craft Origin Provenance Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'GI Origin • ${item.craftAttributes?.clusterLocation?.split(',').first ?? 'Pune Craft Cluster'}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹$activePrice',
                style: AppTextStyles.priceLarge.copyWith(
                  fontSize: 28,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MRP ₹$mrp',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEAE0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$discountPercent% OFF',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondaryTerracotta,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Inclusive of all taxes',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // ── TACTILE PRICING CORRIDOR SELECTOR (Directive: Zero Typing) ──
          Text(
            'FAIR-PRICE CORRIDOR • उचित मूल्य चयन',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTerracotta,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // 1. Floor Cost
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTier = 'floor';
                      _overridePrice = floorPrice;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _selectedTier == 'floor' ? const Color(0xFFFBECE5) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedTier == 'floor' ? AppColors.secondaryTerracotta : AppColors.cardBorder,
                        width: _selectedTier == 'floor' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('Floor Cost', style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('₹$floorPrice', style: AppTextStyles.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('लागत', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 2. Fair Market (Recommended)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTier = 'fair';
                      _overridePrice = baseFairPrice;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _selectedTier == 'fair' ? AppColors.primaryContainer : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedTier == 'fair' ? AppColors.primaryTeal : AppColors.cardBorder,
                        width: _selectedTier == 'fair' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RECOMMENDED',
                            style: AppTextStyles.caption.copyWith(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('₹$baseFairPrice', style: AppTextStyles.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryTeal)),
                        Text('उचित दर', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 3. Premium Price
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTier = 'premium';
                      _overridePrice = premiumPrice;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: _selectedTier == 'premium' ? const Color(0xFFFBECE5) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedTier == 'premium' ? AppColors.secondaryTerracotta : AppColors.cardBorder,
                        width: _selectedTier == 'premium' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('Premium', style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('₹$premiumPrice', style: AppTextStyles.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('प्रीमियम', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nudge buttons: [- ₹50] and [+ ₹50]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    final curr = _overridePrice ?? activePrice;
                    if (curr > 50) _overridePrice = curr - 50;
                  });
                },
                icon: const Icon(Icons.remove, size: 14),
                label: const Text('- ₹50'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              Text(
                'Nudge Price • कीमत बदलें',
                style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    final curr = _overridePrice ?? activePrice;
                    _overridePrice = curr + 50;
                  });
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('+ ₹50'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── TACTILE QUANTITY SELECTOR (Pill Chips: 1, 2, 5, 10 + Stepper) ──
          Text(
            'AVAILABLE STOCK / उपलब्ध मात्रा',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryTerracotta,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              ...[1, 2, 5, 10].map((qty) {
                final isSelected = _quantity == qty;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _quantity = qty),
                    child: Container(
                      width: 42,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryTeal : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryTeal : AppColors.cardBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$qty',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),

              // Stepper for custom counts
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                      child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_quantity',
                        style: AppTextStyles.label.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _quantity++),
                      child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Voice Edit Assistant Drawer ───────────────────────────────────────────
  void _openVoiceEditDrawer(BuildContext context, int currentPrice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: AppColors.primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Edit Assistant',
                        style: AppTextStyles.serifTitle().copyWith(fontSize: 16),
                      ),
                      Text(
                        'बोलून बदल करा • Speak in any language',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Listening Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Listening... (ऐकत आहे)',
                      style: AppTextStyles.label.copyWith(color: AppColors.primaryTeal, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '"Price 300 nahi, 350 karo."',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Detected: Hindi/Hinglish (Price Adjustment)',
                            style: AppTextStyles.caption.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Proposed AI changes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBECE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Listing Price', style: AppTextStyles.caption.copyWith(fontSize: 11)),
                        Text(
                          '₹$currentPrice',
                          style: AppTextStyles.label.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal, size: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Proposed New Price', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryTeal, fontSize: 11)),
                        Text(
                          '₹350',
                          style: AppTextStyles.serifHeading().copyWith(
                            color: AppColors.primaryTeal,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Drawer action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _overridePrice = 350;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Price updated to ₹350 by voice!'),
                            backgroundColor: AppColors.primaryTeal,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Confirm Change'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── 3. About this craft Card ───────────────────────────────────────────────
  Widget _buildAboutCraftCard(CatalogItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primaryTeal, size: 18),
              const SizedBox(width: 6),
              Text(
                'About this craft',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 17),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.voice);
                },
                child: Row(
                  children: [
                    const Icon(Icons.mic_outlined, size: 14, color: AppColors.primaryTeal),
                    const SizedBox(width: 4),
                    Text(
                      'Edit voice notes',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryTeal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Story description
          Text(
            item.descriptionEn ??
                'Beautiful handmade terracotta diya crafted using traditional techniques passed down through generations. Molded with locally sourced clay and dried under gentle sunlight. Perfect for Diwali, festive celebrations, pooja rituals, and mindful home decor.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // Audio Voice Note Player Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF1EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondaryTerracotta.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPlayingAudio = !_isPlayingAudio);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryTerracotta,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingAudio ? Icons.pause_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Listen in ${item.audioLanguage} (${item.audioLanguage == "Marathi" ? "मराठी" : "हिंदी"})',
                            style: AppTextStyles.label.copyWith(fontSize: 13),
                          ),
                          Text(
                            'Artisan voice note • 0:${item.audioDurationSeconds} sec',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBECE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Voice verified',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondaryTerracotta,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Audio waveform bars
                Row(
                  children: List.generate(
                    28,
                    (i) => Expanded(
                      child: Container(
                        height: (i % 4 == 0 ? 14 : (i % 2 == 0 ? 8 : 18)).toDouble(),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: i < 11
                              ? AppColors.secondaryTerracotta
                              : AppColors.secondaryTerracotta.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Meet the Artisan Card ───────────────────────────────────────────────
  Widget _buildMeetArtisanCard(CatalogItem item) {
    final artisanName = item.craftAttributes?.artisanName ?? 'Savita Patil';
    final location = item.craftAttributes?.clusterLocation ?? 'Pune, Maharashtra';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Meet the Artisan',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 17),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, size: 12, color: AppColors.primaryTeal),
                    const SizedBox(width: 4),
                    Text(
                      'Master Craftsman',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryTeal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Artisan Profile Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBECE5).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artisanName,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Traditional Potter & Artisan',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            location,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quote Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“ ',
                  style: AppTextStyles.serifHeading(color: AppColors.secondaryTerracotta)
                      .copyWith(fontSize: 24, height: 1),
                ),
                Expanded(
                  child: Text(
                    'Made by hand with traditional generational clay techniques. Every diya carries the fragrance of our soil and Diwali prayers.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Product Specifications Card ─────────────────────────────────────────
  Widget _buildSpecificationsCard(CatalogItem item) {
    final materials = item.craftAttributes?.materials.isNotEmpty == true
        ? item.craftAttributes!.materials.join(', ')
        : 'Natural Terracotta Clay';
    final guild = item.guildName ?? 'Pune Rural Pottery Cluster';
    final dimensions = item.craftAttributes?.dimensions ?? '180g • 3.5 x 2.0 inches';
    final technique = item.craftTechnique ?? 'Hand Wheel & Embossed Carving';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Specifications',
            style: AppTextStyles.serifTitle().copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),

          _buildSpecRow('Category', 'Festive Home Decor', true),
          _buildSpecRow('Material', materials, false),
          _buildSpecRow('Craft Technique', technique, true),
          _buildSpecRow('Origin Guild', guild, false),
          _buildSpecRow('Weight & Dimensions', dimensions, true),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFFFF8ED) : Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.label.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Fulfilment & Delivery Card ──────────────────────────────────────────
  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: AppColors.primaryTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                'Fulfilment & Delivery',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 17),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEAE0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Free Delivery',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondaryTerracotta),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFBECE5).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Arrival: 12 – 15 Oct',
                  style: AppTextStyles.label.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Delivering to: Mumbai 400001',
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    Text(
                      'Change Pin',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryTeal),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildTrustTag(Icons.eco_outlined, 'Eco Packaging'),
              const SizedBox(width: 12),
              _buildTrustTag(Icons.security_outlined, 'Breakage Guaranteed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }

  // ── 7. Buyer Simulation ────────────────────────────────────────────────────
  Widget _buildBuyerSimulation(int activePrice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'BUYER INTERFACE SIMULATION',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              const Icon(Icons.visibility_outlined, size: 14, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 6),
                      Text('Add to Cart', style: AppTextStyles.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text('Buy Now', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Center(
            child: GestureDetector(
              onTap: () => _openVoiceEditDrawer(context, activePrice),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Edit by Voice • आवाज़ से बदलें',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Bar ──────────────────────────────────────────────────────
  Widget _buildBottomActionBar(
    BuildContext context,
    CatalogController catalogCtrl,
    CatalogItem item,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Audio Readback Bar
          GestureDetector(
            onTap: () => catalogCtrl.speakReadback(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warmSand),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: catalogCtrl.isSpeaking
                          ? AppColors.accentTerracotta
                          : AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      catalogCtrl.isSpeaking
                          ? Icons.volume_up
                          : Icons.headphones_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      catalogCtrl.isSpeaking
                          ? 'सुनाई दे रहा है... (Playing audio readback)'
                          : 'सुनें: ऑडियो पुष्टि • Listen to audio summary',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    catalogCtrl.isSpeaking ? 'Playing' : 'Play',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Draft saved locally in Karigar archive!'),
                    backgroundColor: AppColors.textPrimary,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border_rounded, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 4),
                  Text('Save Draft', style: AppTextStyles.labelSmall),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isPublishing
                  ? null
                  : () async {
                      setState(() => _isPublishing = true);
                      try {
                        await catalogCtrl.publishToOndc(
                          null,
                          _quantity,
                        );
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.successGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Published to ONDC!',
                                  style: AppTextStyles.serifTitle(),
                                ),
                              ],
                            ),
                            content: Text(
                              'Your craft "${item.titleEn}" has been successfully broadcast to ONDC buyer apps via BazaarSetu BPP.',
                              style: AppTextStyles.body,
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _navigateBackToExplore(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryTeal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Back to Home'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Publish result: $e'),
                            backgroundColor: AppColors.primaryTeal,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isPublishing = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Publish Product',
                          style: AppTextStyles.buttonLabel.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
