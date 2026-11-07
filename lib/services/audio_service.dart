import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../config/constants.dart';

class AudioService {
  AudioRecorder? _recorderInstance;
  AudioPlayer? _playerInstance;
  FlutterTts? _ttsInstance;

  AudioRecorder get _recorder => _recorderInstance ??= AudioRecorder();
  AudioPlayer get _player => _playerInstance ??= AudioPlayer();
  FlutterTts get _tts => _ttsInstance ??= FlutterTts();

  StreamSubscription<Amplitude>? _amplitudeSub;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  // ── Initialization ──────────────────────────────────────────────────────

  Future<void> initTts() async {
    try {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('[AudioService] TTS init error: $e');
    }
  }

  // ── Recording ───────────────────────────────────────────────────────────

  /// Check microphone permission.
  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Start recording. Returns amplitude stream (dBFS).
  Future<Stream<double>> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    String? path;
    if (!kIsWeb) {
      final tempDir = await getTemporaryDirectory();
      path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    }

    await _recorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.wav,
        sampleRate: AppConstants.audioSampleRate,
        numChannels: 1,
      ),
      path: path ?? '',
    );

    _isRecording = true;

    // Stream amplitude in dBFS every 80ms
    final controller = StreamController<double>.broadcast();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      if (!controller.isClosed) controller.add(amp.current);
    });

    return controller.stream;
  }

  /// Stop recording. Returns path to the audio file.
  Future<String?> stopRecording() async {
    _isRecording = false;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    final path = await _recorder.stop();
    return path;
  }

  // ── Playback ─────────────────────────────────────────────────────────────

  Future<void> playFile(String path) async {
    final source = kIsWeb ? UrlSource(path) : DeviceFileSource(path);
    await _player.play(source);
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  /// Plays a base64-encoded WAV/audio returned by Bhashini TTS.
  /// Decodes and writes to a temp file, then plays it.
  Future<void> playBase64Audio(String base64Audio) async {
    final bytes = base64Decode(base64Audio);
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/bhashini_tts_${DateTime.now().millisecondsSinceEpoch}.wav';
    await File(path).writeAsBytes(bytes);
    await playFile(path);
  }

  // ── TTS Readback ─────────────────────────────────────────────────────────

  /// Read back complete generated catalog summary in Hindi via TTS.
  Future<void> speakCatalogSummary({
    required String? titleHi,
    required int? fairPrice,
    required String? category,
    List<String>? materials,
    int? laborDays,
    String? descriptionHi,
  }) async {
    await initTts();
    final text = _buildReadbackText(
      titleHi: titleHi,
      fairPrice: fairPrice,
      category: category,
      materials: materials,
      laborDays: laborDays,
      descriptionHi: descriptionHi,
    );
    await _tts.speak(text);
  }

  Future<void> stopTts() async {
    await _tts.stop();
  }

  /// Speak an error / warning prompt in Hindi
  Future<void> speakText(String hindiText) async {
    try {
      await initTts();
      await _tts.speak(hindiText);
    } catch (e) {
      debugPrint('[AudioService] TTS speak error: $e');
    }
  }

  /// Speak an error / warning prompt in Hindi
  Future<void> speakWarning(String hindiText) async {
    try {
      await initTts();
      await _tts.speak(hindiText);
    } catch (e) {
      debugPrint('[AudioService] TTS speakWarning error: $e');
    }
  }

  // ── Disposal ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    await _amplitudeSub?.cancel();
    await _recorderInstance?.dispose();
    await _playerInstance?.dispose();
    await _ttsInstance?.stop();
  }

  // ── Private ──────────────────────────────────────────────────────────────

  String _buildReadbackText({
    required String? titleHi,
    required int? fairPrice,
    required String? category,
    List<String>? materials,
    int? laborDays,
    String? descriptionHi,
  }) {
    final parts = <String>[];
    if (titleHi != null && titleHi.isNotEmpty) {
      parts.add('सामान का नाम: $titleHi।');
    }
    if (category != null && category.isNotEmpty) {
      parts.add('श्रेणी: $category।');
    }
    if (materials != null && materials.isNotEmpty) {
      parts.add('सामग्री: ${materials.join(", ")}।');
    }
    if (laborDays != null && laborDays > 0) {
      parts.add('बनाने में लगे: $laborDays दिन।');
    }
    if (fairPrice != null && fairPrice > 0) {
      parts.add('उचित बिक्री मूल्य: $fairPrice रुपये।');
    }
    if (descriptionHi != null && descriptionHi.isNotEmpty) {
      parts.add('विवरण: $descriptionHi');
    }
    return parts.join(' ');
  }
}
