import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/controllers/voice_controller.dart';
import 'package:project_zerotype/services/audio_service.dart';

class FakeAudioService extends AudioService {
  final StreamController<double> _controller = StreamController<double>.broadcast();
  bool startCalled = false;
  bool stopCalled = false;

  @override
  Future<Stream<double>> startRecording() async {
    startCalled = true;
    return _controller.stream;
  }

  @override
  Future<String?> stopRecording() async {
    stopCalled = true;
    return '/tmp/recorded_voice.wav';
  }

  void emitAmplitude(double amp) {
    _controller.add(amp);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceController Tests', () {
    late FakeAudioService fakeAudioService;
    late VoiceController controller;

    setUp(() {
      fakeAudioService = FakeAudioService();
      controller = VoiceController(audioService: fakeAudioService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is idle with 0 seconds and no audio path', () {
      expect(controller.state, equals(VoiceState.idle));
      expect(controller.recordingSeconds, equals(0));
      expect(controller.audioPath, isNull);
      expect(controller.hasRecording, isFalse);
      expect(controller.amplitudeHistory.length, equals(30));
      expect(controller.isSilent, isFalse);
    });

    test('Category anchors return appropriate prompts for Hindi and English', () {
      // Apparel
      expect(
        VoiceController.getAnchorPrompt('apparel', lang: 'hi'),
        contains('कपड़ा'),
      );
      expect(
        VoiceController.getAnchorPrompt('apparel', lang: 'en'),
        contains('fabric'),
      );

      // Pottery
      expect(
        VoiceController.getAnchorPrompt('pottery', lang: 'hi'),
        contains('मिट्टी'),
      );
      expect(
        VoiceController.getAnchorPrompt('pottery', lang: 'en'),
        contains('clay or ceramic'),
      );

      // Wood & Metal
      expect(
        VoiceController.getAnchorPrompt('wood_metal', lang: 'hi'),
        contains('लकड़ी या धातु'),
      );
      expect(
        VoiceController.getAnchorPrompt('wood_metal', lang: 'en'),
        contains('wood or metal'),
      );

      // Food
      expect(
        VoiceController.getAnchorPrompt('food', lang: 'hi'),
        contains('पैकेट'),
      );
      expect(
        VoiceController.getAnchorPrompt('food', lang: 'en'),
        contains('packet'),
      );

      // Unknown category falls back gracefully
      expect(
        VoiceController.getAnchorPrompt('unknown_xyz', lang: 'hi'),
        contains('माइक दबाकर 2 बातें बताएं'),
      );
      expect(
        VoiceController.getAnchorPrompt('unknown_xyz', lang: 'en'),
        contains('Speak into mic 2 things'),
      );
    });

    test('toggleRecording starts and stops recording accurately', () async {
      expect(controller.state, equals(VoiceState.idle));

      // 1. Start recording
      await controller.toggleRecording();
      expect(controller.state, equals(VoiceState.recording));
      expect(fakeAudioService.startCalled, isTrue);

      // Emit amplitude
      fakeAudioService.emitAmplitude(-20.0);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(controller.amplitudeHistory.last, greaterThan(0.0));

      // 2. Stop recording
      await controller.toggleRecording();
      expect(controller.state, equals(VoiceState.stopped));
      expect(fakeAudioService.stopCalled, isTrue);
      expect(controller.hasRecording, isTrue);
      expect(controller.audioPath, equals('/tmp/recorded_voice.wav'));
    });

    test('reset clears recorded state back to idle', () async {
      await controller.toggleRecording();
      await controller.toggleRecording();
      expect(controller.hasRecording, isTrue);

      controller.reset();
      expect(controller.state, equals(VoiceState.idle));
      expect(controller.audioPath, isNull);
      expect(controller.recordingSeconds, equals(0));
      expect(controller.hasRecording, isFalse);
    });
  });
}
