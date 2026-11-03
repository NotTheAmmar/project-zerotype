import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/catalog_item.dart';
import '../../models/craft_attributes.dart';
import '../../models/pricing_corridor.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _quantity = 1;
  int _selectedThumb = 0;
  bool _isPublishing = false;
  int? _overridePrice;
  String _selectedTier = 'fair'; // 'floor' | 'fair' | 'premium'

  List<String> _getGalleryImages(CatalogItem item) {
    final captureCtrl = context.read<CaptureController>();
    final list = <String>[];
    if (captureCtrl.capturedAngles.isNotEmpty) {
      list.addAll(captureCtrl.capturedAngles.values);
    }
    if (item.studioImagePath != null && !list.contains(item.studioImagePath!)) {
      list.add(item.studioImagePath!);
    }
    if (item.rawImagePath != null && !list.contains(item.rawImagePath!)) {
      list.add(item.rawImagePath!);
    }
    return list;
  }

  Widget _buildFallbackImagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.palette_outlined, size: 44, color: AppColors.secondaryTerracotta),
            SizedBox(height: 6),
            Text(
              'शिल्प छायाचित्र • Artisan Craft Photo',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        appBar: _buildAppBar(context, item, catalogCtrl),
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
                        // 0. Quick Action Edit Bar (Two options: Voice Edit AI + Manual Form)
                        _buildEditQuickActionBar(context, catalogCtrl, item),
                        const SizedBox(height: 14),

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
                        _buildAboutCraftCard(item, catalogCtrl),
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
  PreferredSizeWidget _buildAppBar(
    BuildContext context, [
    CatalogItem? item,
    CatalogController? catalogCtrl,
  ]) {
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
        if (catalogCtrl != null)
          IconButton(
            tooltip: 'बोलकर सुधारें • AI Voice Edit',
            icon: const Icon(Icons.mic_rounded, color: AppColors.secondaryTerracotta),
            onPressed: () => _showVoiceEditSheet(context, catalogCtrl),
          ),
        if (item != null && catalogCtrl != null)
          IconButton(
            tooltip: 'मैन्युअल सुधारें • Manual Edit',
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryTeal),
            onPressed: () => _showManualEditSheet(context, item, catalogCtrl),
          ),
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

  // ── 0. Quick Action Edit Bar (Two Options: Voice AI + Manual Form) ────────
  Widget _buildEditQuickActionBar(
    BuildContext context,
    CatalogController catalogCtrl,
    CatalogItem item,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, color: AppColors.primaryTeal, size: 18),
              const SizedBox(width: 6),
              Text(
                'कैटलॉग में सुधार करें • Two Edit Options',
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Option B (Preferred AI Voice Edit)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showVoiceEditSheet(context, catalogCtrl),
                  icon: const Icon(Icons.mic_rounded, size: 18, color: Colors.white),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'बोलकर सुधारें • AI Voice',
                      style: AppTextStyles.buttonLabel.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryTerracotta,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Option A (Manual Keyboard / UI Edit)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showManualEditSheet(context, item, catalogCtrl),
                  icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primaryTeal),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'मैन्युअल सुधारें • Form',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    side: const BorderSide(color: AppColors.primaryTeal),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 1. Hero Image Section ──────────────────────────────────────────────────
  Widget _buildImageSection(CatalogItem item) {
    final images = _getGalleryImages(item);
    final String? activeImagePath = images.isNotEmpty
        ? images[_selectedThumb % images.length]
        : (item.studioImagePath ?? item.rawImagePath);

    Widget buildImageWidget(String? path) {
      if (path != null && path.isNotEmpty) {
        if (!path.startsWith('http') && File(path).existsSync()) {
          return Image.file(File(path), fit: BoxFit.cover);
        } else if (path.startsWith('http')) {
          return Image.network(
            path,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackImagePlaceholder(),
          );
        }
      }
      return _buildFallbackImagePlaceholder();
    }

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
                  buildImageWidget(activeImagePath),

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
                          '${images.isNotEmpty ? (_selectedThumb % images.length + 1) : 1}/${images.isNotEmpty ? images.length : 1}',
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
              ...List.generate(images.isNotEmpty ? images.length.clamp(0, 4) : 1, (i) {
                final isSelected = _selectedThumb == i;
                final thumbPath = images.isNotEmpty ? images[i] : null;
                final isLocalThumb = thumbPath != null && !thumbPath.startsWith('http') && File(thumbPath).existsSync();

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
                    child: thumbPath != null
                        ? (isLocalThumb
                            ? Image.file(File(thumbPath), fit: BoxFit.cover)
                            : Image.network(
                                thumbPath,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _buildFallbackImagePlaceholder(),
                              ))
                        : _buildFallbackImagePlaceholder(),
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
    final catalogCtrl = context.read<CatalogController>();
    _showVoiceEditSheet(context, catalogCtrl);
  }

  void _showVoiceEditSheet(BuildContext context, CatalogController catalogCtrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceEditBottomSheet(catalogCtrl: catalogCtrl),
    );
  }

  void _showManualEditSheet(
    BuildContext context,
    CatalogItem item,
    CatalogController catalogCtrl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualEditBottomSheet(
        item: item,
        catalogCtrl: catalogCtrl,
      ),
    );
  }

  // ── 3. About this craft Card ───────────────────────────────────────────────
  Widget _buildAboutCraftCard(CatalogItem item, CatalogController catalogCtrl) {
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
                'About this craft • शिल्प विवरण',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 17),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _showVoiceEditSheet(context, catalogCtrl);
                },
                child: Row(
                  children: [
                    const Icon(Icons.mic_outlined, size: 14, color: AppColors.secondaryTerracotta),
                    const SizedBox(width: 4),
                    Text(
                      'बोलकर सुधारें',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.secondaryTerracotta,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Story description
          Text(
            item.descriptionHi ?? item.descriptionEn ??
                'पारंपरिक कारीगरी द्वारा हस्तनिर्मित उत्कृष्ट उत्पाद।',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (item.descriptionEn != null && item.descriptionHi != null) ...[
            const SizedBox(height: 8),
            Text(
              item.descriptionEn!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Audio Voice Note Player Card (Synthesized generated listing readback)
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
                        if (catalogCtrl.isSpeaking) {
                          catalogCtrl.stopReadback();
                        } else {
                          catalogCtrl.speakReadback();
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: catalogCtrl.isSpeaking
                              ? AppColors.alertRed
                              : AppColors.secondaryTerracotta,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          catalogCtrl.isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catalogCtrl.isSpeaking
                                ? 'विवरण सुना रहे हैं • Speaking...'
                                : 'शिल्प विवरण एवं मूल्य सुनें',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            catalogCtrl.isSpeaking
                                ? 'Tap to stop'
                                : 'AI संश्लेषित विवरण • Synthesized Readback',
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catalogCtrl.isSpeaking
                            ? AppColors.tertiarySaffron.withValues(alpha: 0.2)
                            : const Color(0xFFFBECE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        catalogCtrl.isSpeaking ? 'Playing' : 'Listen',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondaryTerracotta,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
                          color: catalogCtrl.isSpeaking
                              ? (i % 2 == 0 ? AppColors.secondaryTerracotta : AppColors.tertiarySaffron)
                              : (i < 11
                                  ? AppColors.secondaryTerracotta
                                  : AppColors.secondaryTerracotta.withValues(alpha: 0.25)),
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
                    color: AppColors.secondaryTerracotta,
                  ),
                  child: Center(
                    child: Text(
                      artisanName.isNotEmpty ? artisanName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bookmark_border_rounded, size: 16, color: AppColors.textPrimary),
                    const SizedBox(width: 4),
                    Text('Save Draft', style: AppTextStyles.labelSmall),
                  ],
                ),
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

// ─────────────────────────────────────────────────────────────────────────────
// OPTION B: AI VOICE EDIT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceEditBottomSheet extends StatefulWidget {
  final CatalogController catalogCtrl;

  const _VoiceEditBottomSheet({required this.catalogCtrl});

  @override
  State<_VoiceEditBottomSheet> createState() => _VoiceEditBottomSheetState();
}

class _VoiceEditBottomSheetState extends State<_VoiceEditBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final AudioService _audioService = AudioService();
  final ApiService _apiService = ApiService();

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isApplying = false;

  static const List<String> _quickSuggestions = [
    'कीमत ₹450 कर दो',
    'सामग्री में पीतल जोड़ें',
    'बनाने में 2 दिन लगे',
    'शीर्षक: हस्तनिर्मित चंदेरी साड़ी',
    'कच्चा माल ₹200 का पड़ा',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });
      try {
        final path = await _audioService.stopRecording();
        if (path != null && path.isNotEmpty) {
          final transcript = await _apiService.transcribeAudio(path);
          if (transcript.isNotEmpty && mounted) {
            _textController.text = transcript;
          }
        }
      } catch (e) {
        debugPrint('[VoiceEdit] recording/transcription error: $e');
      } finally {
        if (mounted) setState(() => _isTranscribing = false);
      }
    } else {
      try {
        await _audioService.startRecording();
        setState(() => _isRecording = true);
      } catch (e) {
        debugPrint('[VoiceEdit] start recording error: $e');
      }
    }
  }

  Future<void> _applyChanges() async {
    final instruction = _textController.text.trim();
    if (instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया बोलें या निर्देश लिखें • Please speak or type instructions')),
      );
      return;
    }

    setState(() => _isApplying = true);
    try {
      await widget.catalogCtrl.applyVoiceUpdate(instruction);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कैटलॉग AI द्वारा अपडेट किया गया! • Listing updated by AI!'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTerracotta.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_fix_high_rounded,
                  color: AppColors.secondaryTerracotta,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'बोलकर सुधारें • AI Voice Edit',
                      style: AppTextStyles.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'माइक दबाकर बोलें कि आप क्या बदलना चाहते हैं',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Mic Button
          Center(
            child: GestureDetector(
              onTap: _isApplying || _isTranscribing ? null : _toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.alertRed : AppColors.secondaryTerracotta,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? AppColors.alertRed : AppColors.secondaryTerracotta).withValues(alpha: 0.35),
                      blurRadius: _isRecording ? 18 : 10,
                      spreadRadius: _isRecording ? 4 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _isRecording
                  ? 'सुन रहे हैं... बोलें • Listening...'
                  : (_isTranscribing
                      ? 'आवाज़ पहचानी जा रही है... • Transcribing...'
                      : 'माइक दबाकर बोलें • Tap mic to speak'),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: _isRecording ? AppColors.alertRed : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickSuggestions.map((sug) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(sug, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.surfaceContainer,
                    onPressed: () {
                      _textController.text = sug;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Instruction Text Input
          TextField(
            controller: _textController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'उदा. "कीमत 450 रुपये कर दो और सामग्री में पीतल लिखो"',
              hintStyle: AppTextStyles.caption.copyWith(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorder),
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isApplying ? null : _applyChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isApplying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'बदलाव लागू करें • Apply Changes',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPTION A: MANUAL FORM EDIT BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ManualEditBottomSheet extends StatefulWidget {
  final CatalogItem item;
  final CatalogController catalogCtrl;

  const _ManualEditBottomSheet({
    required this.item,
    required this.catalogCtrl,
  });

  @override
  State<_ManualEditBottomSheet> createState() => _ManualEditBottomSheetState();
}

class _ManualEditBottomSheetState extends State<_ManualEditBottomSheet> {
  late final TextEditingController _titleHiCtrl;
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _materialsCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _rawCostCtrl;
  late final TextEditingController _laborDaysCtrl;
  late final TextEditingController _dimensionsCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _descHiCtrl;
  late final TextEditingController _descEnCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleHiCtrl = TextEditingController(text: item.titleHi ?? '');
    _titleEnCtrl = TextEditingController(text: item.titleEn ?? '');
    _categoryCtrl = TextEditingController(text: item.craftAttributes?.category ?? '');
    _materialsCtrl = TextEditingController(text: item.craftAttributes?.materials.join(', ') ?? '');
    _priceCtrl = TextEditingController(text: '${item.pricing?.fairPrice ?? 350}');
    _rawCostCtrl = TextEditingController(text: '${item.pricing?.rawMaterialCost ?? 100}');
    _laborDaysCtrl = TextEditingController(text: '${item.craftAttributes?.laborDays ?? 1}');
    _dimensionsCtrl = TextEditingController(text: item.craftAttributes?.dimensions ?? '');
    _quantityCtrl = TextEditingController(text: '${item.availableQuantity}');
    _descHiCtrl = TextEditingController(text: item.descriptionHi ?? '');
    _descEnCtrl = TextEditingController(text: item.descriptionEn ?? '');
  }

  @override
  void dispose() {
    _titleHiCtrl.dispose();
    _titleEnCtrl.dispose();
    _categoryCtrl.dispose();
    _materialsCtrl.dispose();
    _priceCtrl.dispose();
    _rawCostCtrl.dispose();
    _laborDaysCtrl.dispose();
    _dimensionsCtrl.dispose();
    _quantityCtrl.dispose();
    _descHiCtrl.dispose();
    _descEnCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final rawCost = int.tryParse(_rawCostCtrl.text) ?? 100;
      final laborDays = int.tryParse(_laborDaysCtrl.text) ?? 1;
      final sellingPrice = int.tryParse(_priceCtrl.text) ?? 350;
      final qty = int.tryParse(_quantityCtrl.text) ?? 1;

      final materials = _materialsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updated = widget.item.copyWith(
        titleHi: _titleHiCtrl.text.trim(),
        titleEn: _titleEnCtrl.text.trim(),
        descriptionHi: _descHiCtrl.text.trim(),
        descriptionEn: _descEnCtrl.text.trim(),
        availableQuantity: qty,
        craftAttributes: (widget.item.craftAttributes ?? const CraftAttributes()).copyWith(
          category: _categoryCtrl.text.trim(),
          materials: materials.isNotEmpty ? materials : widget.item.craftAttributes?.materials,
          laborDays: laborDays,
          dimensions: _dimensionsCtrl.text.trim(),
        ),
        pricing: PricingCorridor.compute(
          rawMaterialCost: rawCost,
          laborDays: laborDays,
          sellerProposedPrice: sellingPrice,
        ),
      );

      await widget.catalogCtrl.updateCurrentItem(updated);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('कैटलॉग विवरण सफलतापूर्वक अपडेट किया गया! • Details saved!'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save error: $e'),
            backgroundColor: AppColors.alertRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'मैन्युअल सुधारें • Edit Craft Form',
                      style: AppTextStyles.label.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'विवरण, कीमत एवं सामग्री को बदलें',
                      style: AppTextStyles.caption.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleHiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'उत्पाद का नाम (हिंदी) • Hindi Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Product Name (English)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'श्रेणी • Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _materialsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'सामग्री • Materials (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'विक्रय मूल्य (₹)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _rawCostCtrl,
                          decoration: const InputDecoration(
                            labelText: 'लागत (₹)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _laborDaysCtrl,
                          decoration: const InputDecoration(
                            labelText: 'श्रम के दिन • Days',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _dimensionsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'माप • Dimensions',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _quantityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'मात्रा • Qty',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descHiCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'विवरण (हिंदी) • Craft Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descEnCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (English)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'सहेजें एवं अपडेट करें • Save Changes',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
