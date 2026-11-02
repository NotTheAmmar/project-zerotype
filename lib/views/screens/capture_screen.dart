import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _tts = FlutterTts();

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

  Future<void> _playAudioTip() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.speak('दीया बीच में रखें और अच्छी रोशनी रखें। साफ तस्वीरें लें।');
    } catch (e) {
      debugPrint('[CaptureScreen] TTS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureController>(
      builder: (context, ctrl, _) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top Header ───────────────────────────────────────────────
                _buildHeader(context),

                // ── Scrollable Body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Guidance Title
                        _buildGuidanceHeader(),
                        const SizedBox(height: 10),

                        // Audio Tips Banner
                        _buildAudioTipBanner(),
                        const SizedBox(height: 12),

                        // 4:3 Camera Viewfinder
                        _buildViewfinder(ctrl),
                        const SizedBox(height: 14),

                        // Multi-Angle Progress Tracker
                        _buildAngleProgressTracker(ctrl),
                        const SizedBox(height: 16),

                        // Shutter & Hardware Dock
                        _buildHardwareControls(ctrl),
                        const SizedBox(height: 14),

                        // Forward Action Button
                        _buildContinueButton(context, ctrl),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 1. Top Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.temple_hindu_rounded,
                    color: AppColors.primaryTeal,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BazaarSetu',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryTeal,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                'Photo Scanning • फ़ोटो स्कैनिंग',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.secondaryTerracotta,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: _playAudioTip,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.headphones_rounded, size: 16, color: AppColors.primaryTeal),
                      const SizedBox(width: 4),
                      Text(
                        'आवाज़',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryTeal),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Guidance Header ─────────────────────────────────────────────────────
  Widget _buildGuidanceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan Your Product',
          style: AppTextStyles.serifHeading().copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'अपने उत्पाद की फोटो लें',
          style: AppTextStyles.label.copyWith(
            color: AppColors.secondaryTerracotta,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take photos of your handmade product to create a catalog.\nअपने हस्तशिल्प उत्पाद की साफ तस्वीरें लें।',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ── 3. Audio Tips Banner ───────────────────────────────────────────────────
  Widget _buildAudioTipBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondaryTerracotta.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AUDIO TIPS • आवाज़ मार्गदर्शन',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryTeal,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'दीया बीच में रखें और अच्छी रोशनी रखें',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _playAudioTip,
            icon: const Icon(Icons.play_arrow_rounded, size: 14),
            label: const Text('सुनें'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryTeal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Viewfinder ──────────────────────────────────────────────────────────
  Widget _buildViewfinder(CaptureController ctrl) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Stream / Fallback Image
            if (ctrl.isCameraReady && ctrl.cameraController != null)
              CameraPreview(ctrl.cameraController!)
            else if (ctrl.capturedImagePath != null)
              kIsWeb
                  ? Image.network(
                      ctrl.capturedImagePath!,
                      fit: BoxFit.cover,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                    )
                  : Image.file(File(ctrl.capturedImagePath!), fit: BoxFit.cover)
            else
              Image.network(
                'https://images.unsplash.com/photo-1603555501671-8f96b3fce8e4?auto=format&fit=crop&w=800&q=80',
                fit: BoxFit.cover,
              ),

            // Rule of thirds grid overlay
            if (ctrl.showGrid)
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white24), bottom: BorderSide(color: Colors.white24))))),
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white24), bottom: BorderSide(color: Colors.white24))))),
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white24), bottom: BorderSide(color: Colors.white24))))),
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white24), bottom: BorderSide(color: Colors.white24))))),
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))))),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white24))))),
                        Expanded(child: Container(decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white24))))),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ),
                ],
              ),

            // Gold/White Corner Focus Brackets
            Positioned(
              top: 16,
              left: 16,
              child: _buildBracket(top: true, left: true),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _buildBracket(top: true, left: false),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildBracket(top: false, left: true),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildBracket(top: false, left: false),
            ),

            // Center Crosshair
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiarySaffron,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Top Overlay Bar: Flash, Status Chip, Grid Toggle
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flash toggle
                  GestureDetector(
                    onTap: ctrl.toggleFlash,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ctrl.flashOn ? Icons.flash_on : Icons.flash_off,
                        color: ctrl.flashOn ? AppColors.tertiarySaffron : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  // Detection Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ctrl.detectedStatusLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Grid guide toggle
                  GestureDetector(
                    onTap: ctrl.toggleGrid,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ctrl.showGrid ? Icons.grid_on : Icons.grid_off,
                        color: ctrl.showGrid ? AppColors.tertiarySaffron : Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Frame Live Helper Notice
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.center_focus_strong, size: 13, color: AppColors.tertiarySaffron),
                      const SizedBox(width: 5),
                      Text(
                        'Keep ${ctrl.detectedObject} inside yellow brackets',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracket({required bool top, required bool left}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              color: AppColors.tertiarySaffron,
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: 3,
              color: AppColors.tertiarySaffron,
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Multi-Angle Progress Tracker ────────────────────────────────────────
  Widget _buildAngleProgressTracker(CaptureController ctrl) {
    const angleLabels = [
      {'en': 'Front', 'hi': 'सामने'},
      {'en': 'Side', 'hi': 'बगल'},
      {'en': 'Back', 'hi': 'पीछे'},
      {'en': 'Detail', 'hi': 'बारीकी'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Photos Taken: ${ctrl.photosTakenCount}/4',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  ' • ${ctrl.photosTakenCount}/४ तस्वीरें',
                  style: AppTextStyles.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFBECE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Next: ${angleLabels[ctrl.activeAngleIndex]['en']} / ${angleLabels[ctrl.activeAngleIndex]['hi']}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondaryTerracotta,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: List.generate(4, (i) {
            final isCaptured = ctrl.capturedAngles.containsKey(i);
            final isActive = ctrl.activeAngleIndex == i;
            final label = angleLabels[i];

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFEEAE0)
                      : (isCaptured ? Colors.white : Colors.white.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryTeal
                        : (isCaptured ? AppColors.secondaryTerracotta.withValues(alpha: 0.3) : AppColors.cardBorder),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: isCaptured
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(ctrl.capturedAngles[i]!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, _, _) => const Center(
                                      child: Icon(Icons.check_circle, color: AppColors.primaryTeal, size: 20),
                                    ),
                                  ),
                                  const Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor: AppColors.primaryTeal,
                                      child: Icon(Icons.check, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  isActive ? Icons.photo_camera : Icons.camera_alt_outlined,
                                  size: 20,
                                  color: isActive ? AppColors.primaryTeal : AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label['en']!,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11,
                        color: isActive ? AppColors.primaryTeal : AppColors.textPrimary,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      label['hi']!,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isCaptured)
                      GestureDetector(
                        onTap: () => ctrl.retakeAngle(i),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'बदलें',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: AppColors.secondaryTerracotta,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── 6. Hardware Shutter Controls ───────────────────────────────────────────
  Widget _buildHardwareControls(CaptureController ctrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Gallery Button
        InkWell(
          onTap: ctrl.pickFromGallery,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 72,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined, color: AppColors.secondaryTerracotta, size: 22),
                const SizedBox(height: 2),
                Text('Gallery', style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
                Text('गैलरी', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),

        // Tactile Shutter Button (Terracotta Secondary Tone)
        GestureDetector(
          onTap: ctrl.capturePhoto,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.secondaryTerracotta,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryTerracotta.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.secondaryTerracotta,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Flip Camera Button
        InkWell(
          onTap: () {
            // Re-trigger camera init or flip toggle
            ctrl.initCamera();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 72,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flip_camera_ios_outlined, color: AppColors.secondaryTerracotta, size: 22),
                const SizedBox(height: 2),
                Text('Flip', style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
                Text('कैमरा बदलें', style: AppTextStyles.caption.copyWith(fontSize: 8, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 7. Continue Forward Action ─────────────────────────────────────────────
  Widget _buildContinueButton(BuildContext context, CaptureController ctrl) {
    final canProceed = ctrl.canProceed;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canProceed
                ? () {
                    Navigator.pushNamed(context, AppRoutes.voice);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryTerracotta,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue • आगे बढ़ें',
                      style: AppTextStyles.buttonLabel.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Next step: Record craft voice story • अगला कदम: बोलकर बताएं',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_rounded, size: 13, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              '1 minimum photo required to proceed • कम से कम १ फोटो आवश्यक',
              style: AppTextStyles.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
