import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/catalog_item.dart';
import '../../models/craft_attributes.dart';
import '../../models/pricing_corridor.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';
import '../widgets/bilingual_text.dart';

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
  CatalogController? _catalogCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _catalogCtrl = context.read<CatalogController>();
  }

  @override
  void dispose() {
    _catalogCtrl?.stopReadback();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final item = context.read<CatalogController>().currentItem;
      if (item != null && mounted) {
        setState(() {
          _quantity = item.availableQuantity;
        });
      }
    });
  }

  Future<void> _setQuantity(int qty, CatalogItem? item, CatalogController? catalogCtrl) async {
    setState(() => _quantity = qty);
    if (item != null && catalogCtrl != null && item.availableQuantity != qty) {
      final updated = item.copyWith(availableQuantity: qty);
      await catalogCtrl.updateCurrentItem(updated);

      if (item.status == CatalogStatus.published && item.pricing != null) {
        try {
          await catalogCtrl.publishToOndc(null, qty);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stock updated to $qty units on ONDC • स्टॉक $qty पीस अपडेट हुआ'),
                backgroundColor: AppColors.primaryTeal,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('[CatalogScreen] Error updating published stock to ONDC BPP: $e');
        }
      }
    }
  }

  List<String> _getGalleryImages(CatalogItem item) {
    final list = <String>[];

    void addUnique(String? path) {
      if (path != null &&
          path.isNotEmpty &&
          !path.contains('photo-1610030469983-98e550d6193c') &&
          !list.contains(path)) {
        list.add(path);
      }
    }

    // 1. Studio image (if present and distinct from raw image)
    if (item.studioImagePath != null && item.studioImagePath != item.rawImagePath) {
      addUnique(item.studioImagePath);
    }

    // 2. Primary raw image
    addUnique(item.rawImagePath);

    // 3. Additional gallery photos
    for (final g in item.galleryImages) {
      addUnique(g);
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

                        // ONDC Live Status Banner (if published)
                        if (item.status == CatalogStatus.published) ...[
                          _buildLiveOndcBanner(item),
                          const SizedBox(height: 14),
                        ],

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
    _catalogCtrl?.stopReadback();
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
      title: Text(
        'Product Detail',
        style: AppTextStyles.label.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        if (catalogCtrl != null && item?.status != CatalogStatus.published)
          IconButton(
            tooltip: 'बोलकर सुधारें • AI Voice Edit',
            icon: const Icon(Icons.mic_rounded, color: AppColors.secondaryTerracotta),
            onPressed: () => _showVoiceEditSheet(context, catalogCtrl),
          ),
        if (item != null && catalogCtrl != null && item.status != CatalogStatus.published)
          IconButton(
            tooltip: 'मैन्युअल सुधारें • Manual Edit',
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryTeal),
            onPressed: () => _showManualEditSheet(context, item, catalogCtrl),
          ),
        if (item != null && catalogCtrl != null && item.status == CatalogStatus.published)
          IconButton(
            tooltip: 'स्टॉक बदलें • Update Stock',
            icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryTeal),
            onPressed: () => _showCustomQuantityDialog(context, item, catalogCtrl),
          ),
        if (item != null && catalogCtrl != null && item.status != CatalogStatus.published)
          IconButton(
            tooltip: 'शिल्प हटाएं • Delete Draft',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed),
            onPressed: () => _confirmDeleteCraft(context, item, catalogCtrl),
          ),
        IconButton(
          tooltip: 'नेटवर्क विवरण • Network Info',
          icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
          onPressed: () {
            if (item != null) {
              _showNetworkStatusDialog(context, item);
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── ONDC Live Status Banner & Actions ───────────────────────────────────────

  Widget _buildLiveOndcBanner(CatalogItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE ON ONDC NETWORK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Active on Beckn rails • ओएनडीसी क्रेता ऐप्स पर उपलब्ध',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'स्टॉक बदलें • Update Stock',
            icon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2E7D32), size: 20),
            onPressed: () => _showCustomQuantityDialog(context, item, context.read<CatalogController>()),
          ),
          IconButton(
            tooltip: 'नेटवर्क विवरण देखें • Network Info',
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32), size: 20),
            onPressed: () => _showNetworkStatusDialog(context, item),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCraft(
    BuildContext context,
    CatalogItem item,
    CatalogController catalogCtrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.alertRed, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Craft? • शिल्प हटाएं?',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.titleEn}"? This action cannot be undone.\n\nक्या आप वाकई इस शिल्प को स्थायी रूप से हटाना चाहते हैं?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel • रद्द करें', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await catalogCtrl.deleteCatalog(item.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Craft deleted successfully • शिल्प हटा दिया गया'),
                  backgroundColor: AppColors.textPrimary,
                ),
              );
              _navigateBackToExplore(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete • हटाएं'),
          ),
        ],
      ),
    );
  }

  void _confirmUnlistCraft(
    BuildContext context,
    CatalogItem item,
    CatalogController catalogCtrl,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.unpublished_outlined, color: AppColors.secondaryTerracotta, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unlist Craft? • अनलिस्ट करें?',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'This will remove "${item.titleEn}" from active buyer searches on ONDC and revert it to a local draft.\n\nयह शिल्प ओएनडीसी क्रेता खोज से हट जाएगा और ड्राफ्ट में वापस आ जाएगा।',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel • रद्द करें', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await catalogCtrl.unpublishCatalog(item);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Craft unlisted from ONDC • शिल्प ड्राफ्ट में बदल दिया गया'),
                  backgroundColor: AppColors.secondaryTerracotta,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryTerracotta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlist • अनलिस्ट करें'),
          ),
        ],
      ),
    );
  }

  void _showNetworkStatusDialog(BuildContext context, CatalogItem item) {
    final bppUri = '${AppConstants.bppBackendUrl}/beckn';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.hub_rounded, color: AppColors.primaryTeal, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ONDC Network Status',
                style: AppTextStyles.serifTitle().copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNetworkDetailRow('Status', item.status == CatalogStatus.published ? 'LIVE ON NETWORK' : 'DRAFT', isBadge: true),
              const SizedBox(height: 8),
              _buildNetworkDetailRow('Catalog SKU', item.id),
              const SizedBox(height: 8),
              _buildNetworkDetailRow('Artisan Name', item.craftAttributes?.artisanName ?? 'BazaarSetu Artisan'),
              const SizedBox(height: 8),
              _buildNetworkDetailRow('Cluster', item.craftAttributes?.clusterLocation ?? 'Chanderi Handloom'),
              const SizedBox(height: 8),
              _buildNetworkDetailRow('ONDC Category', '${item.craftAttributes?.category ?? "Craft"} (ONDC:RET12)'),
              const SizedBox(height: 8),
              _buildNetworkDetailRow('Fair Price', '₹${item.pricing?.fairPrice ?? 0}'),
              const SizedBox(height: 8),
              _buildNetworkDetailRow('BPP Node', bppUri),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catalog ID copied to clipboard')),
              );
            },
            child: const Text('Copy ID'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done • पूर्ण'),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkDetailRow(String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B5E20),
              ),
            ),
          )
        else
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
      ],
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
                onPressed: () => _showVoiceEditSheet(context, context.read<CatalogController>()),
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

          // Bilingual Title: English prominently, Hindi/local below
          BilingualText(
            english: item.titleEn ?? 'Handcrafted Artisan Item',
            local: item.titleHi,
            englishStyle: AppTextStyles.serifHeading(
              color: AppColors.textPrimary,
            ).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            localStyle: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
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

          // Custom price input row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Custom Price • अपनी कीमत',
                style: AppTextStyles.caption.copyWith(fontSize: 11, color: AppColors.textSecondary),
              ),
              OutlinedButton.icon(
                onPressed: () => _showCustomPriceDialog(context, activePrice),
                icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryTeal),
                label: Text(
                  '₹$activePrice  •  बदलें',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  side: const BorderSide(color: AppColors.primaryTeal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── TACTILE QUANTITY SELECTOR (Pill Chips: 1, 2, 5, 10, 25, 50 + Custom Numeric Entry) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'AVAILABLE STOCK / उपलब्ध मात्रा',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryTerracotta,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showCustomQuantityDialog(context, item, context.read<CatalogController>()),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined, size: 13, color: AppColors.primaryTeal),
                    const SizedBox(width: 3),
                    Text(
                      'संख्या लिखें • Enter Custom',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...[1, 2, 5, 10, 25, 50].map((qty) {
                  final isSelected = _quantity == qty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _setQuantity(qty, item, context.read<CatalogController>()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                // Custom Chip
                GestureDetector(
                  onTap: () => _showCustomQuantityDialog(context, item, context.read<CatalogController>()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: ![1, 2, 5, 10, 25, 50].contains(_quantity)
                          ? AppColors.primaryTeal
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ![1, 2, 5, 10, 25, 50].contains(_quantity)
                            ? AppColors.primaryTeal
                            : AppColors.cardBorder,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 15,
                          color: ![1, 2, 5, 10, 25, 50].contains(_quantity)
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ![1, 2, 5, 10, 25, 50].contains(_quantity) ? '$_quantity' : 'Custom',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ![1, 2, 5, 10, 25, 50].contains(_quantity)
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

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
                          if (_quantity > 1) {
                            _setQuantity(_quantity - 1, item, context.read<CatalogController>());
                          }
                        },
                        child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                      ),
                      GestureDetector(
                        onTap: () => _showCustomQuantityDialog(context, item, context.read<CatalogController>()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '$_quantity',
                            style: AppTextStyles.label.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dotted,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _setQuantity(_quantity + 1, item, context.read<CatalogController>()),
                        child: const Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Custom Quantity Dialog (for large quantities like 100, 250, 500) ─────────
  void _showCustomQuantityDialog(BuildContext context, CatalogItem? item, CatalogController? catalogCtrl) {
    final controller = TextEditingController(text: '$_quantity');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.primaryTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'उपलब्ध स्टॉक • Set Stock',
                style: AppTextStyles.label.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'आपके पास कुल कितने पीस उपलब्ध हैं? (उदा: 50, 100, 500)',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'स्टॉक मात्रा / Total Units',
                  hintText: 'उदा: 100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [10, 25, 50, 100, 250, 500].map((quick) {
                  return ActionChip(
                    label: Text('+$quick'),
                    onPressed: () {
                      final curr = int.tryParse(controller.text) ?? 0;
                      controller.text = '${curr + quick}';
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('रद्द करें • Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                _setQuantity(val, item, catalogCtrl);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('लागू करें • Apply'),
          ),
        ],
      ),
    );
  }

  // ── Custom Price Dialog ────────────────────────────────────────────────────
  void _showCustomPriceDialog(BuildContext context, int currentPrice) {
    final controller = TextEditingController(text: '$currentPrice');
    showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('कीमत दर्ज करें\nEnter Custom Price'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: 'e.g. 350',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('रद्द करें • Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(val);
            },
            child: const Text('ठीक है • OK'),
          ),
        ],
      ),
    ).then((val) {
      if (val != null && val > 0) {
        setState(() => _overridePrice = val);
      }
    });
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
              Expanded(
                child: Text(
                  'About Craft • शिल्प विवरण',
                  style: AppTextStyles.serifTitle().copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _showVoiceEditSheet(context, catalogCtrl);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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

          // Bilingual Story description: English first, Hindi/local underneath
          BilingualText(
            english: item.descriptionEn ?? 'Authentic handcrafted product made with traditional techniques and generational artisan skill.',
            local: item.descriptionHi,
            englishStyle: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            localStyle: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
            spacing: 8.0,
          ),
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
    final attrs = item.craftAttributes;
    final materials = attrs?.materials.isNotEmpty == true
        ? attrs!.materials.join(', ')
        : null;
    final guild = item.guildName;
    final dimensions = attrs?.dimensions;
    final weight = attrs?.weight;
    final technique = item.craftTechnique;
    final category = attrs?.category ?? item.craftAttributes?.genericName;

    // Combine weight + dimensions if both present, otherwise show whichever exists
    final weightDimensions = [
      if (weight != null && weight.isNotEmpty) weight,
      if (dimensions != null && dimensions.isNotEmpty) dimensions,
    ].join(' • ');

    int rowIndex = 0;

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

          if (category != null && category.isNotEmpty)
            _buildSpecRow('Category', category, rowIndex++ % 2 == 0),
          if (materials != null)
            _buildSpecRow('Material', materials, rowIndex++ % 2 == 0),
          if (technique != null && technique.isNotEmpty)
            _buildSpecRow('Craft Technique', technique, rowIndex++ % 2 == 0),
          if (guild != null && guild.isNotEmpty)
            _buildSpecRow('Craft Cluster', guild, rowIndex++ % 2 == 0),
          if (weightDimensions.isNotEmpty)
            _buildSpecRow('Weight & Dimensions', weightDimensions, rowIndex++ % 2 == 0),
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
          if (item.status == CatalogStatus.published)
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => _confirmUnlistCraft(context, item, catalogCtrl),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppColors.secondaryTerracotta),
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
                          const Icon(
                            Icons.unpublished_outlined,
                            size: 16,
                            color: AppColors.secondaryTerracotta,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unlist • ड्राफ्ट बनाएं',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.secondaryTerracotta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _showNetworkStatusDialog(context, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.hub_outlined, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Network Info • ओएनडीसी स्थिति',
                            style: AppTextStyles.buttonLabel.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 48,
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
                                  Expanded(
                                    child: Text(
                                      'Published to ONDC! • ओएनडीसी पर लाइव!',
                                      style: AppTextStyles.label.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                'Your craft "${item.titleEn}" has been successfully broadcast to ONDC buyer apps via BazaarSetu BPP.\n\nयह शिल्प ओएनडीसी नेटवर्क पर सक्रिय हो चुका है।',
                                style: AppTextStyles.body,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Stay on Listing • यहीं रहें'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _navigateBackToExplore(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Back to Crafts • मुख्य पृष्ठ'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Publish result: $e'),
                              backgroundColor: AppColors.alertRed,
                            ),
                          );
                        } finally {
                          if (mounted) setState(() => _isPublishing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryTerracotta,
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
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ओएनडीसी पर प्रकाशित करें • Publish to ONDC',
                              style: AppTextStyles.buttonLabel.copyWith(
                                fontSize: 14,
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
