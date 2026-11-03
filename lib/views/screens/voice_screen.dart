import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../controllers/capture_controller.dart';
import '../../controllers/voice_controller.dart';
import '../widgets/mic_button.dart';
import '../widgets/waveform_visualizer.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _promptSpoken = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_promptSpoken && mounted) {
        _promptSpoken = true;
        _speakCategoryPrompt();
      }
    });
  }

  Future<void> _speakCategoryPrompt() async {
    final captureCtrl = context.read<CaptureController>();
    final promptHi = VoiceController.getAnchorPrompt(captureCtrl.detectedCategory, lang: 'hi');
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.speak(promptHi);
    } catch (e) {
      debugPrint('[VoiceScreen] TTS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaptureController, VoiceController>(
      builder: (context, captureCtrl, voiceCtrl, _) {
        final category = captureCtrl.detectedCategory;
        final promptHi = VoiceController.getAnchorPrompt(category, lang: 'hi');
        final promptEn = VoiceController.getAnchorPrompt(category, lang: 'en');

        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.screenV,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ── Top bar ───────────────────────────────────────────
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            voiceCtrl.reset();
                            Navigator.of(context).pop();
                          },
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text('आवाज़ रिकॉर्ड करें', style: AppTextStyles.subhead),
                            Text('Voice Story Narration', style: AppTextStyles.caption.copyWith(fontSize: 10)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.volume_up_outlined, color: AppColors.primaryTeal),
                          onPressed: _speakCategoryPrompt,
                          tooltip: 'आवाज़ सुनें',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Captured image thumbnail + detected category ──────
                    if (captureCtrl.capturedImagePath != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: kIsWeb
                                ? Image.network(
                                    captureCtrl.capturedImagePath!,
                                    height: 110,
                                    width: 110,
                                    fit: BoxFit.cover,
                                    headers: const {'ngrok-skip-browser-warning': 'true'},
                                  )
                                : Image.file(
                                    File(captureCtrl.capturedImagePath!),
                                    height: 110,
                                    width: 110,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          if (captureCtrl.hasDetectedObject) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${captureCtrl.detectedObject} • ${captureCtrl.detectedCategory.toUpperCase()}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.secondaryTerracotta,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Craft Story Question Banner ───────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.secondaryTerracotta.withValues(alpha: 0.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.record_voice_over_rounded, size: 18, color: AppColors.secondaryTerracotta),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  captureCtrl.hasDetectedObject
                                      ? 'CATEGORY ADAPTIVE QUESTION'
                                      : 'CRAFT STORY QUESTIONS • कारीगर विवरण',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.secondaryTerracotta,
                                    letterSpacing: 0.8,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.play_circle_outline, color: AppColors.primaryTeal, size: 20),
                                onPressed: _speakCategoryPrompt,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            promptHi,
                            style: AppTextStyles.label.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            promptEn,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Recording Timer (Open-ended count up, no 15s limit) ─
                    _RecordingTimer(
                      seconds: voiceCtrl.recordingSeconds,
                      isRecording: voiceCtrl.state == VoiceState.recording,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Mic button ────────────────────────────────────────
                    MicButton(
                      isRecording: voiceCtrl.state == VoiceState.recording,
                      onTap: voiceCtrl.toggleRecording,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Waveform ──────────────────────────────────────────
                    WaveformVisualizer(
                      amplitudes: voiceCtrl.amplitudeHistory,
                      isActive: voiceCtrl.state == VoiceState.recording,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ── Silence warning ───────────────────────────────────
                    AnimatedOpacity(
                      opacity: voiceCtrl.isSilent && voiceCtrl.state == VoiceState.recording ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmberLight,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          border: Border.all(color: AppColors.warningAmber),
                        ),
                        child: Text(
                          '🔔 आवाज़ ठीक से नहीं आई — phone पास लाएं',
                          style: AppTextStyles.caption.copyWith(color: AppColors.warningAmber),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Proceed button (after recording stops) ────────────
                    AnimatedOpacity(
                      opacity: voiceCtrl.hasRecording ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: voiceCtrl.hasRecording
                              ? () => Navigator.of(context).pushNamed(AppRoutes.processing)
                              : null,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('AI से catalog बनाएं • Create Catalog'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecordingTimer extends StatelessWidget {
  final int seconds;
  final bool isRecording;
  const _RecordingTimer({required this.seconds, required this.isRecording});

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _format(seconds),
          style: AppTextStyles.headlineLarge.copyWith(
            color: isRecording ? AppColors.alertRed : AppColors.textPrimary,
            fontSize: 44,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          isRecording ? 'Recording... बोल रहे हैं' : (seconds > 0 ? 'Recorded • रिकॉर्ड हुआ' : 'Tap mic to start'),
          style: AppTextStyles.caption.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
