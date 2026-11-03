import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  int _lastSpokenStep = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _speakCurrentStepQuestion();
      }
    });
  }

  Future<void> _speakCurrentStepQuestion() async {
    final voiceCtrl = context.read<VoiceController>();
    if (_lastSpokenStep == voiceCtrl.currentStep) return;
    _lastSpokenStep = voiceCtrl.currentStep;

    final question = voiceCtrl.currentStepData.questionHi;
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.speak(question);
    } catch (e) {
      debugPrint('[VoiceScreen] TTS speak error: $e');
    }
  }

  Future<void> _replayTts() async {
    final voiceCtrl = context.read<VoiceController>();
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.speak(voiceCtrl.currentStepData.questionHi);
    } catch (e) {
      debugPrint('[VoiceScreen] TTS replay error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaptureController, VoiceController>(
      builder: (context, captureCtrl, voiceCtrl, _) {
        final step = voiceCtrl.currentStepData;
        final isRecorded = voiceCtrl.isCurrentStepRecorded;

        return Scaffold(
          backgroundColor: AppColors.warmCream,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                        onPressed: () {
                          if (!voiceCtrl.isFirstStep) {
                            voiceCtrl.previousStep();
                            _speakCurrentStepQuestion();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'सवाल ${voiceCtrl.currentStep + 1} / ${voiceCtrl.totalSteps} • ${step.titleHi}',
                              style: AppTextStyles.label.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              step.titleEn,
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined, color: AppColors.primaryTeal),
                        onPressed: _replayTts,
                        tooltip: 'सवाल सुनें',
                      ),
                    ],
                  ),
                ),

                // ── Stepper Progress Indicator ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: List.generate(voiceCtrl.totalSteps, (idx) {
                      final isActive = voiceCtrl.currentStep == idx;
                      final isDone = voiceCtrl.stepAudioPaths.containsKey(idx);

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            voiceCtrl.jumpToStep(idx);
                            _speakCurrentStepQuestion();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.primaryTeal
                                  : (isActive ? AppColors.secondaryTerracotta : Colors.black12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Scrollable Body ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        // Craft Thumbnail & Current Step Badge
                        if (captureCtrl.capturedImagePath != null)
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: (!kIsWeb && File(captureCtrl.capturedImagePath!).existsSync())
                                  ? Image.file(
                                      File(captureCtrl.capturedImagePath!),
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 90,
                                      width: 90,
                                      color: Colors.black12,
                                      child: const Icon(Icons.image_outlined, size: 36, color: Colors.black45),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 14),

                        // ── Question Card ──────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.secondaryTerracotta.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.record_voice_over_rounded,
                                    size: 16,
                                    color: AppColors.secondaryTerracotta,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'STEP ${voiceCtrl.currentStep + 1} OF ${voiceCtrl.totalSteps}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondaryTerracotta,
                                      letterSpacing: 0.8,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                step.questionHi,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                step.questionEn,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Dimensions & Size Manual UI (Step 4 only) ───────
                        if (voiceCtrl.currentStep == 3) ...[
                          _buildDimensionsManualUi(voiceCtrl),
                          const SizedBox(height: 18),
                        ],

                        // ── Recording Timer & State ────────────────────────
                        _RecordingTimer(
                          seconds: voiceCtrl.recordingSeconds,
                          isRecording: voiceCtrl.state == VoiceState.recording,
                        ),
                        const SizedBox(height: 16),

                        // ── Mic Button ─────────────────────────────────────
                        MicButton(
                          isRecording: voiceCtrl.state == VoiceState.recording,
                          onTap: voiceCtrl.toggleRecording,
                        ),
                        const SizedBox(height: 14),

                        // ── Waveform Visualizer ────────────────────────────
                        WaveformVisualizer(
                          amplitudes: voiceCtrl.amplitudeHistory,
                          isActive: voiceCtrl.state == VoiceState.recording,
                        ),
                        const SizedBox(height: 12),

                        // Recorded Confirmation Banner
                        if (isRecorded && voiceCtrl.state != VoiceState.recording)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'रिकॉर्ड हो गया • Answer Saved',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: voiceCtrl.clearCurrentStepAudio,
                                  child: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Fixed Action Bar ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
                  ),
                  child: Row(
                    children: [
                      // Back / Skip
                      if (!voiceCtrl.isFirstStep) ...[
                        OutlinedButton(
                          onPressed: () {
                            voiceCtrl.previousStep();
                            _speakCurrentStepQuestion();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('← पिछला • Back'),
                        ),
                        const SizedBox(width: 10),
                      ],

                      // Forward / Next or Finish
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (!voiceCtrl.isLastStep) {
                              voiceCtrl.nextStep();
                              _speakCurrentStepQuestion();
                            } else {
                              Navigator.of(context).pushNamed(AppRoutes.processing);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: voiceCtrl.isLastStep
                                ? AppColors.primaryTeal
                                : AppColors.secondaryTerracotta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          icon: Icon(
                            voiceCtrl.isLastStep ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                          label: Text(
                            voiceCtrl.isLastStep
                                ? 'कैटलॉग बनाएं • Create Catalog'
                                : 'अगला सवाल • Next Step →',
                            style: AppTextStyles.buttonLabel.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Manual UI for Dimensions & Measurements ─────────────────────────────────
  Widget _buildDimensionsManualUi(VoiceController voiceCtrl) {
    const units = ['cm', 'inch', 'meter', 'gram', 'kg'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten_rounded, color: AppColors.primaryTeal, size: 18),
              const SizedBox(width: 6),
              Text(
                'माप एवं आकार (वैकल्पिक) • Manual Dimensions',
                style: AppTextStyles.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: voiceCtrl.manualLength,
                  decoration: const InputDecoration(
                    labelText: 'लंबाई / Length',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => voiceCtrl.setManualDimensions(length: val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: voiceCtrl.manualWidth,
                  decoration: const InputDecoration(
                    labelText: 'चौड़ाई / Width',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => voiceCtrl.setManualDimensions(width: val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Unit Selector Chips
          Row(
            children: [
              Text('इकाई • Unit: ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: units.map((u) {
                    final isSel = voiceCtrl.manualUnit == u;
                    return ChoiceChip(
                      label: Text(u, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.textPrimary)),
                      selected: isSel,
                      selectedColor: AppColors.primaryTeal,
                      backgroundColor: AppColors.surfaceContainer,
                      onSelected: (_) => voiceCtrl.setManualDimensions(unit: u),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
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
            fontSize: 40,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          isRecording
              ? 'Recording... बोल रहे हैं'
              : (seconds > 0 ? 'Recorded • रिकॉर्ड हुआ' : 'माइक दबाकर बोलें • Tap mic to speak'),
          style: AppTextStyles.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}
