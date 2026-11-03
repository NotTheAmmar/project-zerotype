import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _cameraInitStarted = false;

  final List<({String hi, String en, IconData icon})> _angleSlots = const [
    (hi: 'सामने', en: 'Front', icon: Icons.crop_portrait_rounded),
    (hi: 'पीछे/साइड', en: 'Back/Side', icon: Icons.crop_rotate_rounded),
    (hi: 'बारीकी', en: 'Detail', icon: Icons.zoom_in_rounded),
    (hi: 'हाथ में', en: 'In Hand', icon: Icons.pan_tool_outlined),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cameraInitStarted && mounted) {
        _cameraInitStarted = true;
        context.read<CaptureController>().initCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Full-Screen Camera Viewfinder ────────────────────────
              _buildCameraPreview(ctrl),

              // ── 2. Subtle 3x3 Composition Grid ──────────────────────────
              if (ctrl.showGrid) _buildGridOverlay(),

              // ── 3. Top Floating App Bar ─────────────────────────────────
              _buildTopBar(context, ctrl),

              // ── 4. Quality Warning Floating Pill ────────────────────────
              if (ctrl.isQualityWarningBlur || ctrl.isQualityWarningLight)
                _buildQualityWarning(ctrl),

              // ── 5. Bottom Interactive Controls Dock ─────────────────────
              _buildBottomDock(context, ctrl),
            ],
          ),
        );
      },
    );
  }

  // ── Full-Screen Camera Preview with BoxFit.cover scale ──────────────────────
  Widget _buildCameraPreview(CaptureController ctrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final camera = ctrl.cameraController;
        if (ctrl.isCameraReady && camera != null && camera.value.isInitialized) {
          var scale = constraints.biggest.aspectRatio * camera.value.aspectRatio;
          if (scale < 1) scale = 1 / scale;

          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth * camera.value.aspectRatio,
                child: CameraPreview(camera),
              ),
            ),
          );
        }

        // Elegant dark camera placeholder when loading or running on desktop/web
        return Container(
          color: const Color(0xFF121212),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 48,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ctrl.isBusy ? 'कैमरा शुरू हो रहा है...' : 'कैमरा तैयार है',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'फोटो खींचें या नीचे गैलरी से चुनें',
                  style: AppTextStyles.caption.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Subtle 3x3 Framing Grid ────────────────────────────────────────────────
  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(child: _buildGridRow()),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          Expanded(child: _buildGridRow()),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          Expanded(child: _buildGridRow()),
        ],
      ),
    );
  }

  Widget _buildGridRow() {
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        Container(width: 1, color: Colors.white.withValues(alpha: 0.18)),
        const Expanded(child: SizedBox()),
        Container(width: 1, color: Colors.white.withValues(alpha: 0.18)),
        const Expanded(child: SizedBox()),
      ],
    );
  }

  // ── Top Floating Bar ───────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, CaptureController ctrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back Button
                _buildCircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),

                // Photos Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${ctrl.photosTakenCount}/4 Photos',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Grid Toggle
                _buildCircleIconButton(
                  icon: ctrl.showGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
                  tooltip: 'Grid',
                  isActive: ctrl.showGrid,
                  onTap: ctrl.toggleGrid,
                ),
                const SizedBox(width: 10),

                // Flash Toggle
                _buildCircleIconButton(
                  icon: ctrl.flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  tooltip: 'Flash',
                  isActive: ctrl.flashOn,
                  onTap: ctrl.toggleFlash,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? AppColors.tertiarySaffron.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.45),
            border: Border.all(
              color: isActive ? AppColors.tertiarySaffron : Colors.white24,
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? AppColors.tertiarySaffron : Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Quality Warning Banner ─────────────────────────────────────────────────
  Widget _buildQualityWarning(CaptureController ctrl) {
    return Positioned(
      top: 90,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningAmber.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_incandescent_outlined, color: Colors.black87, size: 16),
              const SizedBox(width: 8),
              Text(
                ctrl.isQualityWarningBlur
                    ? 'फोटो थोड़ी धुंधली है • Hold camera steady'
                    : 'कम रोशनी • Better light recommended',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Controls Dock ───────────────────────────────────────────────────
  Widget _buildBottomDock(BuildContext context, CaptureController ctrl) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.92),
              Colors.black.withValues(alpha: 0.65),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Angle Selector Chips ──
                _buildAngleSelectorChips(ctrl),
                const SizedBox(height: 18),

                // ── Shutter & Actions Row ──
                _buildShutterRow(context, ctrl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Horizontal Angle Selector Chips ────────────────────────────────────────
  Widget _buildAngleSelectorChips(CaptureController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_angleSlots.length, (index) {
        final slot = _angleSlots[index];
        final isSelected = ctrl.activeAngleIndex == index;
        final capturedPath = ctrl.capturedAngles[index];
        final isCaptured = capturedPath != null;

        return Expanded(
          child: GestureDetector(
            onTap: () => ctrl.selectAngleSlot(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryTeal.withValues(alpha: 0.3)
                    : (isCaptured
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : (isCaptured ? Colors.white54 : Colors.white24),
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isCaptured && !kIsWeb && File(capturedPath).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(capturedPath),
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Icon(
                          slot.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.primaryTeal
                              : (isCaptured ? Colors.white : Colors.white60),
                        ),
                      if (isCaptured)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.hi,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    slot.en,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? AppColors.primaryTeal : Colors.white54,
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Shutter Row ────────────────────────────────────────────────────────────
  Widget _buildShutterRow(BuildContext context, CaptureController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Gallery Button
        SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                onPressed: ctrl.isBusy ? null : ctrl.pickFromGallery,
                tooltip: 'गैलरी से चुनें',
              ),
              Text(
                'गैलरी • Pick',
                style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),

        // Shutter Button
        GestureDetector(
          onTap: ctrl.isBusy ? null : ctrl.capturePhoto,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ctrl.isBusy
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Next / Voice Button
        SizedBox(
          width: 72,
          child: ctrl.canProceed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pushNamed(AppRoutes.voice);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'आगे • Voice',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
