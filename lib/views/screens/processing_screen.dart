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
  late final AnimationController _pulseController;
  Timer? _progressTimer;
  Timer? _tipTimer;
  int _progressPercent = 15;
  int _currentTipIndex = 0;

  static const List<Map<String, String>> _craftTips = [
    {
      'icon': '✨',
      'title': 'High-Impact Photos',
      'subtitle': 'Clean studio lighting increases buyer orders on ONDC by over 3x.',
      'hi': 'अच्छी रोशनी और साफ बैकग्राउंड से ओएनडीसी पर 3 गुना अधिक ऑर्डर मिलते हैं।',
    },
    {
      'icon': '🌿',
      'title': 'Authentic Heritage',
      'subtitle': 'Mentioning traditional materials and your craft cluster builds buyer trust.',
      'hi': 'सामग्री और शिल्प क्षेत्र (क्लस्टर) की जानकारी से खरीदारों का भरोसा बढ़ता है।',
    },
    {
      'icon': '⚖️',
      'title': 'Fair Artisan Pricing',
      'subtitle': 'BazaarSetu ensures you earn 100% of your labor value without broker cuts.',
      'hi': 'बाज़ारसेतु सुनिश्चित करता है कि आपकी पूरी मेहनत की कमाई सीधे आपको मिले।',
    },
    {
      'icon': '🚀',
      'title': 'Nationwide Reach',
      'subtitle': 'Your product will be discoverable on major buyer apps across India.',
      'hi': 'आपका शिल्प पूरे भारत के बड़े खरीदार ऐप्स (पेटीएम, माईस्टोर) पर दिखेगा।',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Gradually advance progress percentage
    _progressTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (mounted) {
        setState(() {
          if (_progressPercent < 90) {
            _progressPercent += 12;
          }
        });
      }
    });

    // Rotate tips every 3.5 seconds
    _tipTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _craftTips.length;
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

    final manualDims = [
      if (voiceCtrl.manualLength.isNotEmpty || voiceCtrl.manualWidth.isNotEmpty)
        'Dimensions: ${voiceCtrl.manualLength}x${voiceCtrl.manualWidth} ${voiceCtrl.manualUnit}',
      if (voiceCtrl.manualWeight.isNotEmpty)
        'Weight: ${voiceCtrl.manualWeight}${voiceCtrl.manualWeightUnit}',
      if (voiceCtrl.manualQuantity.isNotEmpty)
        'Quantity: ${voiceCtrl.manualQuantity}',
    ].join(', ');

    try {
      await catalogCtrl.processCatalog(
        imagePath: captureCtrl.capturedImagePath ?? '',
        audioPath: voiceCtrl.audioPath ?? '',
        audioPaths: voiceCtrl.stepAudioPaths.values.toList(),
        manualDimensions: manualDims.isNotEmpty ? manualDims : null,
      );
    } catch (e) {
      debugPrint('[ProcessingScreen] processing error: $e');
    }

    if (!mounted) return;

    if (catalogCtrl.stage == ProcessingStage.done) {
      setState(() {
        _progressPercent = 100;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
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
      (route) => route.isFirst,
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
    _progressTimer?.cancel();
    _tipTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final captureCtrl = context.watch<CaptureController>();
    final catalogCtrl = context.watch<CatalogController>();

    final isError = catalogCtrl.stage == ProcessingStage.error;
    final isDone = catalogCtrl.stage == ProcessingStage.done;

    final tip = _craftTips[_currentTipIndex];

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Top AI Badge ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBECE5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.secondaryTerracotta.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: AppColors.secondaryTerracotta,
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
                  const SizedBox(height: 18),

                  // ── Title & Subtitle ──────────────────────────────────────
                  Text(
                    isDone
                        ? 'Catalog Ready!'
                        : (isError ? 'Notice' : 'Crafting your listing...'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serifHeadingLarge(
                      color: isError ? AppColors.alertRed : AppColors.textPrimary,
                    ).copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isDone
                        ? 'आपका डिजिटल कैटलॉग तैयार है!'
                        : (isError
                            ? 'कैटलॉग निर्माण में कुछ देरी हुई'
                            : 'डिजिटल कैटलॉग तैयार किया जा रहा है...'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.serifTitle(
                      color: isDone ? AppColors.primaryTeal : AppColors.secondaryTerracotta,
                    ).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Hero Craft Photo Centerpiece with Breathing Ring ──────
                  _buildHeroCraftPreview(captureCtrl.capturedImagePath, isDone),
                  const SizedBox(height: 24),

                  // ── Sleek Progress Bar with Percentage Counter ────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isDone
                                    ? 'Analysis Complete • पूर्ण हुआ'
                                    : _getStageHeadline(catalogCtrl.stage),
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? AppColors.primaryTeal : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isDone ? '100%' : '$_progressPercent%',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: isDone ? 1.0 : (_progressPercent / 100.0).clamp(0.05, 0.95),
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceContainer,
                            valueColor: AlwaysStoppedAnimation(
                              isDone ? AppColors.primaryTeal : AppColors.secondaryTerracotta,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDone
                            ? 'All product details and fair pricing are ready.'
                            : _getStageDetail(catalogCtrl.stage),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Rotating Artisan Knowledge / Tips Card ────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      key: ValueKey<int>(_currentTipIndex),
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondaryTerracotta.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip['icon']!, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip['title']!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip['hi']!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.secondaryTerracotta,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip['subtitle']!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Error Banner (if connection issue) ─────────────────────
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
                                'AI सहायता • AI Assistance',
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            catalogCtrl.errorMessage ?? 'सर्वर से जवाब नहीं मिला। आपकी खींची गई फोटो और आवाज़ सुरक्षित है।',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() => _progressPercent = 15);
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

                  // ── Bottom Action Button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isDone
                          ? _navigateToListingPreview
                          : (isError ? _createManualDraftAndProceed : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDone ? AppColors.primaryTeal : AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.black12,
                        disabledForegroundColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isDone && !isError) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            isDone
                                ? 'View Listing Preview → सूची देखें'
                                : (isError
                                    ? 'Open Draft Listing • ड्राफ्ट खोलें'
                                    : 'Processing craft details... प्रतीक्षा करें'),
                            style: AppTextStyles.buttonLabel.copyWith(
                              fontSize: 14,
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
                  ),
                  const SizedBox(height: 10),

                  Text(
                    '🔒 All artisan photos & voice recordings are saved locally',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero Craft Photo with Animated Glowing Ambient Ring ───────────────────
  Widget _buildHeroCraftPreview(String? localImagePath, bool isDone) {
    const double size = 150;
    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Ambient Breathing Outer Ring
          RotationTransition(
            turns: _pulseController,
            child: SizedBox(
              width: size + 28,
              height: size + 28,
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  color: isDone
                      ? AppColors.primaryTeal
                      : AppColors.secondaryTerracotta.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // Craft Image
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDone ? AppColors.primaryTeal : AppColors.secondaryTerracotta)
                      .withValues(alpha: 0.2),
                  blurRadius: 18,
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

          // Floating Status Pill
          Positioned(
            bottom: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDone ? AppColors.primaryTeal : AppColors.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone ? Icons.check_circle_rounded : Icons.auto_fix_high_rounded,
                    size: 14,
                    color: isDone ? AppColors.primaryTeal : AppColors.secondaryTerracotta,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDone ? 'Craft Ready • पूर्ण हुआ' : 'AI Craft Studio',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDone ? AppColors.primaryTeal : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStageHeadline(ProcessingStage stage) {
    switch (stage) {
      case ProcessingStage.imageProcessing:
        return 'Enhancing Studio Photography • फोटो संपादन';
      case ProcessingStage.voiceProcessing:
        return 'Transcribing Artisan Speech • आवाज़ का विश्लेषण';
      case ProcessingStage.pricing:
        return 'Calculating Fair Price • उचित मूल्य निर्धारण';
      case ProcessingStage.done:
        return 'Listing Completed • कैटलॉग तैयार';
      case ProcessingStage.error:
        return 'Attention Needed • सहायता आवश्यक';
      default:
        return 'Analyzing Craft Details • विश्लेषण जारी';
    }
  }

  String _getStageDetail(ProcessingStage stage) {
    switch (stage) {
      case ProcessingStage.imageProcessing:
        return 'Preparing studio photography for buyer apps...';
      case ProcessingStage.voiceProcessing:
        return 'Transcribing voice notes and extracting craft attributes...';
      case ProcessingStage.pricing:
        return 'Computing statutory floor & fair market corridor...';
      case ProcessingStage.done:
        return 'All product details and fair pricing are ready.';
      default:
        return 'Formatting Beckn ONDC schema and attributes...';
    }
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
