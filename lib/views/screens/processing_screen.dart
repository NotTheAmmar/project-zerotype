import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  bool _hasNavigated = false;
  late final AnimationController _dashPulse;
  Timer? _stepTimer;
  int _completedSteps = 1;

  @override
  void initState() {
    super.initState();
    _dashPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          if (_completedSteps < 5) {
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
      debugPrint('[ProcessingScreen] processing error: $e');
    }

    if (!mounted) return;

    if (catalogCtrl.stage == ProcessingStage.done) {
      setState(() {
        _completedSteps = 6;
      });
      // Auto-navigate to CatalogScreen after a brief 600ms visual confirmation
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && !_hasNavigated) {
          _navigateToListingPreview();
        }
      });
    }
  }

  void _navigateToListingPreview() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.catalog,
      ModalRoute.withName(AppRoutes.explore),
    );
  }

  void _createManualDraftAndProceed() async {
    final captureCtrl = context.read<CaptureController>();
    final voiceCtrl = context.read<VoiceController>();
    final catalogCtrl = context.read<CatalogController>();

    await catalogCtrl.createFallbackDraft(
      imagePath: captureCtrl.capturedImagePath ?? '',
      audioPath: voiceCtrl.audioPath,
      category: captureCtrl.detectedCategory,
    );

    if (mounted) {
      _navigateToListingPreview();
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _dashPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureCtrl = context.watch<CaptureController>();
    final catalogCtrl = context.watch<CatalogController>();

    final isError = catalogCtrl.stage == ProcessingStage.error;
    final isDone = catalogCtrl.stage == ProcessingStage.done;

    // Calculate real effective steps
    int activeStepCount = _completedSteps;
    if (isDone) {
      activeStepCount = 6;
    } else if (catalogCtrl.stage == ProcessingStage.voiceProcessing) {
      activeStepCount = activeStepCount < 3 ? 3 : activeStepCount;
    } else if (catalogCtrl.stage == ProcessingStage.pricing) {
      activeStepCount = activeStepCount < 5 ? 5 : activeStepCount;
    }

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
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

                  // ── Title ───────────────────────────────────────────────────
                  Text(
                    isError
                        ? 'Processing Note'
                        : 'Creating your product\nlisting...',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serifHeadingLarge(
                      color: isError ? AppColors.alertRed : AppColors.textPrimary,
                    ).copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Hindi Subtitle ──────────────────────────────────────────
                  Text(
                    isError
                        ? 'कैटलॉग निर्माण में कुछ देरी हुई'
                        : 'आपके उत्पाद की जानकारी तैयार की जा रही है',
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
                      isError
                          ? 'इंटरनेट कनेक्शन या AI सेवा में रुकावट आई। आप दोबारा प्रयास कर सकते हैं या सीधे ड्राफ्ट में जाकर विवरण भर सकते हैं।'
                          : 'Crafting bilingual storytelling, fair-price corridor, and marketplace tags directly from your craft photo & voice.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Circular Photo Frame with Dashed Arc ─────────────────────
                  _buildCircularPreview(captureCtrl.capturedImagePath),
                  const SizedBox(height: 24),

                  // ── Error Banner (if error occurred) ────────────────────────
                  if (isError) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmberLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warningAmber),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.warningAmber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'AI विश्लेषण सहायता • AI Assistance',
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            catalogCtrl.errorMessage ?? 'सर्वर से जवाब नहीं मिला। आपकी खींची गई फोटो सुरक्षित है।',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _completedSteps = 1;
                                    });
                                    _startProcessing();
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('दोबारा प्रयास • Retry'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryTeal,
                                    side: const BorderSide(color: AppColors.primaryTeal),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _createManualDraftAndProceed,
                                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                                  label: const Text('ड्राफ्ट खोलें • Draft'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTeal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── 6 Step Progress Cards ───────────────────────────────────
                  _buildStepCard(
                    stepNumber: 1,
                    title: 'Photos received & analyzed',
                    subtitle: 'Angles captured and image quality verified',
                    isCompleted: activeStepCount >= 1,
                    isActive: activeStepCount == 0,
                    completedBadge: '100%',
                  ),
                  const SizedBox(height: 10),

                  _buildStepCard(
                    stepNumber: 2,
                    title: 'Voice notes transcribed',
                    subtitle: 'Speech-to-text transcription via Whisper / Bhashini',
                    isCompleted: activeStepCount >= 2,
                    isActive: activeStepCount == 1,
                    completedBadge: 'Done',
                  ),
                  const SizedBox(height: 10),

                  _buildStepCard(
                    stepNumber: 3,
                    title: 'Craft attributes extracted',
                    subtitle: 'Analyzing materials, craft cluster, and dimensions',
                    isCompleted: activeStepCount >= 3,
                    isActive: activeStepCount == 2,
                    completedBadge: 'Done',
                  ),
                  const SizedBox(height: 10),

                  _buildStepCard(
                    stepNumber: 4,
                    title: 'Creating bilingual descriptions',
                    subtitle: 'Writing Hindi & English artisan storytelling...',
                    isCompleted: activeStepCount >= 4,
                    isActive: activeStepCount == 3,
                    activeBadge: 'Writing',
                    completedBadge: 'Done',
                  ),
                  const SizedBox(height: 10),

                  _buildStepCard(
                    stepNumber: 5,
                    title: 'Suggesting category & pricing',
                    subtitle: 'Fair artisan rate corridor computed from raw material & labor',
                    isCompleted: activeStepCount >= 5,
                    isActive: activeStepCount == 4,
                    activeBadge: 'Pricing',
                    completedBadge: 'Done',
                  ),
                  const SizedBox(height: 10),

                  _buildStepCard(
                    stepNumber: 6,
                    title: 'Preparing marketplace listing',
                    subtitle: 'Formatting verified ONDC Beckn catalog data',
                    isCompleted: activeStepCount >= 6,
                    isActive: activeStepCount == 5,
                    activeBadge: 'Listing',
                    completedBadge: 'Done',
                  ),
                  const SizedBox(height: 24),

                  // ── Footer Status ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isDone ? '✅ ' : '⏳ ', style: const TextStyle(fontSize: 16)),
                      Text(
                        isDone
                            ? 'Ready! सूची तैयार है'
                            : (isError ? 'Action required • नीचे चुनें' : 'Almost ready... लगभग तैयार है'),
                        style: AppTextStyles.label.copyWith(
                          color: isDone ? AppColors.primaryTeal : AppColors.secondaryTerracotta,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Primary Action Button ───────────────────────────────────
                  ElevatedButton(
                    onPressed: isDone
                        ? _navigateToListingPreview
                        : (isError ? _createManualDraftAndProceed : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDone ? AppColors.primaryTeal : AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.black12,
                      disabledForegroundColor: Colors.black38,
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
                          isDone
                              ? 'View Listing Preview → सूची देखें'
                              : (isError ? 'Open Draft Listing • ड्राफ्ट खोलें' : 'Analyzing craft... कृपया प्रतीक्षा करें'),
                          style: AppTextStyles.buttonLabel.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'All artisan work is safely stored on your device',
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
        ),
      ),
    );
  }

  // ── Circular Image Frame with Dashed Radial Outer Ring ───────────────────────────
  Widget _buildCircularPreview(String? localImagePath) {
    const double size = 160;
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
              child: (localImagePath != null && !kIsWeb && File(localImagePath).existsSync())
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

          // Bottom Pill: "● AI Crafting"
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
                    'AI Crafting',
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
      cardBg = const Color(0xFFFDF1EC);
      borderColor = AppColors.secondaryTerracotta.withValues(alpha: 0.35);
    } else if (!isCompleted) {
      cardBg = const Color(0xFFFAF6F2);
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
