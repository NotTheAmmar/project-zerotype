import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../controllers/voice_controller.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  bool _started = false;
  late final AnimationController _dashPulse;
  Timer? _stepTimer;
  int _completedSteps = 1; // 1 to 6

  @override
  void initState() {
    super.initState();
    _dashPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Step progression timer to provide interactive feedback
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        setState(() {
          if (_completedSteps < 6) {
            _completedSteps++;
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startProcessing());
    }
  }

  Future<void> _startProcessing() async {
    final captureCtrl = context.read<CaptureController>();
    final voiceCtrl = context.read<VoiceController>();
    final catalogCtrl = context.read<CatalogController>();

    try {
      await catalogCtrl.processCatalog(
        imagePath: captureCtrl.capturedImagePath ?? '',
        audioPath: voiceCtrl.audioPath ?? '',
      );
    } catch (e) {
      debugPrint('[ProcessingScreen] error: $e');
    }

    if (!mounted) return;
    setState(() {
      _completedSteps = 6;
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _dashPulse.dispose();
    super.dispose();
  }

  void _navigateToListingPreview() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.catalog);
  }

  @override
  Widget build(BuildContext context) {
    final captureCtrl = context.watch<CaptureController>();
    final catalogCtrl = context.watch<CatalogController>();
    final isFinished = _completedSteps >= 6 && catalogCtrl.stage == ProcessingStage.done;

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Top Pill Badge ──────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBECE5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.secondaryTerracotta.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: AppColors.primaryTeal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BAZAARSETU KARIGAR AI',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.secondaryTerracotta,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── English Title ───────────────────────────────────────────
              Text(
                'Creating your product\nlisting...',
                textAlign: TextAlign.center,
                style: AppTextStyles.serifHeadingLarge(
                  color: AppColors.textPrimary,
                ).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),

              // ── Hindi Subtitle ──────────────────────────────────────────
              Text(
                'आपके उत्पाद की जानकारी तैयार की जा रही है',
                textAlign: TextAlign.center,
                style: AppTextStyles.serifTitle(
                  color: AppColors.secondaryTerracotta,
                ).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // ── Explanatory description ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Crafting bilingual storytelling, smart pricing, and marketplace tags directly from your handcraft photo & voice.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Circular Photo Frame with Dashed Arc ─────────────────────
              _buildCircularPreview(captureCtrl.capturedImagePath),
              const SizedBox(height: 28),

              // ── 6 Step Progress Cards ───────────────────────────────────
              _buildStepCard(
                stepNumber: 1,
                title: 'Photos analyzed',
                subtitle: 'Clay texture, petal rim & flame depth verified',
                isCompleted: _completedSteps >= 1,
                isActive: _completedSteps == 0,
                completedBadge: '100%',
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 2,
                title: 'Product recognized',
                subtitle: 'Kutch Hand-Carved Mitti Diya (Terracotta Lamp)',
                isCompleted: _completedSteps >= 2,
                isActive: _completedSteps == 1,
                completedBadge: 'Done',
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 3,
                title: 'Voice notes transcribed',
                subtitle: 'Gujarati/Hindi artisan voice translated to English',
                isCompleted: _completedSteps >= 3,
                isActive: _completedSteps == 2,
                completedBadge: 'Done',
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 4,
                title: 'Creating product description',
                subtitle: 'Highlighting organic earthen clay & festive utility...',
                isCompleted: _completedSteps >= 4,
                isActive: _completedSteps == 3,
                activeBadge: 'Writing',
                completedBadge: 'Done',
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 5,
                title: 'Suggesting category & pricing',
                subtitle: 'Home & Festive Decor • Fair artisan rate',
                isCompleted: _completedSteps >= 5,
                isActive: _completedSteps == 4,
                activeBadge: 'Pricing',
                completedBadge: 'Done',
              ),
              const SizedBox(height: 10),

              _buildStepCard(
                stepNumber: 6,
                title: 'Preparing marketplace listing',
                subtitle: 'Generating buyer tags & shipping dimensions',
                isCompleted: _completedSteps >= 6,
                isActive: _completedSteps == 5,
                activeBadge: 'Listing',
                completedBadge: 'Done',
              ),
              const SizedBox(height: 24),

              // ── Footer Status ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⏳ ', style: TextStyle(fontSize: 16)),
                  Text(
                    isFinished
                        ? 'Ready! सूची तैयार है'
                        : 'Almost ready... लगभग तैयार है',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.secondaryTerracotta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Primary Action Button ───────────────────────────────────
              ElevatedButton(
                onPressed: _navigateToListingPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Step Complete → View Listing Preview',
                      style: AppTextStyles.buttonLabel.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Helper Text
              Text(
                'Tap button above to preview the completed Karigar listing',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Circular Image Frame with Dashed Radial Outer Ring ───────────────────────────
  Widget _buildCircularPreview(String? localImagePath) {
    const double size = 180;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Dashed Outer Ring
          RotationTransition(
            turns: _dashPulse,
            child: SizedBox(
              width: size + 24,
              height: size + 24,
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  color: AppColors.primaryTeal.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // Circular Image Container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: (localImagePath != null && File(localImagePath).existsSync())
                  ? Image.file(
                      File(localImagePath),
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      'https://images.unsplash.com/photo-1603555501671-8f96b3fce8e4?auto=format&fit=crop&w=800&q=80',
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // Bottom Pill: "● < AI Crafting"
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiarySaffron,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '< AI Crafting',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step Card Widget ───────────────────────────────────────────────────────
  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    String? activeBadge,
    required String completedBadge,
  }) {
    Color cardBg = Colors.white;
    Color borderColor = AppColors.cardBorder;

    if (isActive) {
      cardBg = const Color(0xFFFDF1EC); // Soft peach
      borderColor = AppColors.secondaryTerracotta.withValues(alpha: 0.35);
    } else if (!isCompleted) {
      cardBg = const Color(0xFFFAF6F2); // Subtle muted cream
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Left Status Icon
          if (isCompleted)
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            )
          else if (isActive)
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
            ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: isCompleted || isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isCompleted || isActive
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive
                        ? AppColors.secondaryTerracotta
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right Status Chip
          if (isCompleted)
            Text(
              completedBadge,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (isActive && activeBadge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFBECE5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryTerracotta,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activeBadge,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.secondaryTerracotta,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Pending',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Custom Painter for Dashed Radial Outer Ring ──────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 28;
    const double sweepAngle = (2 * 3.1415926535) / dashCount;

    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * sweepAngle,
          sweepAngle * 0.65,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
