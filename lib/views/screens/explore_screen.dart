import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/catalog_item.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final catalogCtrl = context.watch<CatalogController>();
    final savedCatalogs = catalogCtrl.savedCatalogs;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isTablet = screenWidth >= 640;
            final int crossAxisCount = screenWidth > 900
                ? 4
                : screenWidth > 600
                    ? 3
                    : 2;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: CustomScrollView(
                  slivers: [
                    // ── App Header ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildTopHeader(context, isTablet),
                    ),

                    // ── Search & Mic Bar ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildSearchBar(context),
                    ),

                    // ── Prototype & Fair Pledge Banner ────────────────────
                    SliverToBoxAdapter(
                      child: _buildPrototypeBanner(context),
                    ),

                    // ── Section Header ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(savedCatalogs.length),
                    ),

                    // ── Product Grid or Empty State ───────────────────────
                    if (savedCatalogs.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(context),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: screenWidth < 360 ? 0.62 : 0.68,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = savedCatalogs[index];
                              return _buildProductCard(context, item);
                            },
                            childCount: savedCatalogs.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ── Top Header (Profile removed) ───────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // BazaarSetu Brand Logo
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.secondaryTerracotta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.temple_hindu_rounded,
              color: AppColors.secondaryTerracotta,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BazaarSetu',
                style: AppTextStyles.serifHeading().copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Karigar AI Studio • Prototype',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),

          // New Craft Listing CTA button in Header
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.capture);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              isTablet ? 'Create Craft Listing' : 'List Craft',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar with Voice Mic ──────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search craft products...',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            // Voice Mic Button -> Opens AI Capture
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.capture);
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: AppColors.primaryTeal,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Direct Karigar Fair Pledge Prototype Banner ────────────────────────────
  Widget _buildPrototypeBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBECE5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondaryTerracotta.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        color: AppColors.secondaryTerracotta,
                        size: 15,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'KARIGAR AI PROTOTYPE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondaryTerracotta,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Voice & Vision Craft Onboarding',
                    style: AppTextStyles.serifTitle(
                      color: AppColors.textPrimary,
                    ).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photograph your handmade craft and speak in your language. The AI pipeline analyzes materials, recommends fair pricing, and drafts your ONDC listing.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondaryTerracotta.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_rounded,
                color: AppColors.secondaryTerracotta,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Text(
            itemCount > 0 ? 'Your Craft Listings' : 'Craft Listings',
            style: AppTextStyles.serifTitle().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$itemCount',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          if (itemCount > 0)
            GestureDetector(
              onTap: () {
                context.read<CatalogController>().loadSavedCatalogs();
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Refresh',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty State (When no user crafts listed yet) ───────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.camera_enhance_rounded,
              size: 34,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Craft Products Listed Yet',
            style: AppTextStyles.serifTitle().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start your prototype journey! Tap below to snap a picture of your craft and speak your artisan story.',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.capture);
              },
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Create First Craft Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryTerracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Product Card (Review & rating removed) ──────────────────────────────────
  Widget _buildProductCard(BuildContext context, CatalogItem item) {
    final fairPrice = item.pricing?.fairPrice ?? 0;
    final mrp = item.mrp;

    return GestureDetector(
      onTap: () {
        final catalogController = context.read<CatalogController>();
        catalogController.setItem(item);
        Navigator.pushNamed(context, AppRoutes.catalog);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(item),
                  // Handmade Tag
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTerracotta.withValues(
                          alpha: 0.9,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Handmade',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  // Status badge (e.g. Published or Draft)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.status == CatalogStatus.published
                            ? AppColors.primaryTeal.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status == CatalogStatus.published
                            ? 'ONDC Live'
                            : 'Draft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details (No review or star rating section)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guild / Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          item.guildName ??
                              item.craftAttributes?.clusterLocation ??
                              'Artisan Guild',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    item.titleEn ?? 'Handmade Craft',
                    style:
                        AppTextStyles.serifSubhead(color: AppColors.textPrimary)
                            .copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Pricing Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        fairPrice > 0 ? '₹$fairPrice' : 'Price Pending',
                        style: AppTextStyles.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (mrp != null && mrp > fairPrice) ...[
                        const SizedBox(width: 4),
                        Text(
                          '₹$mrp',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(CatalogItem item) {
    final imagePath = item.studioImagePath ?? item.rawImagePath;

    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        color: AppColors.surfaceContainer,
        child: const Center(
          child: Icon(
            Icons.brush_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }

  // ── Bottom Navigation Bar (Categories & Profile removed) ───────────────────
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 1) {
            // Karigar Hub: Start AI Product Creation
            Navigator.pushNamed(context, AppRoutes.capture);
          } else {
            setState(() => _bottomNavIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primaryTeal,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Crafts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded, size: 26),
            activeIcon: Icon(Icons.add_circle_rounded, size: 26),
            label: 'Karigar Hub',
          ),
        ],
      ),
    );
  }
}
