import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/constants.dart';
import '../services/audio_service.dart';

enum VoiceState { idle, recording, stopped }

class VoiceController extends ChangeNotifier {
  final AudioService _audioService;

  VoiceController({required this._audioService});

  VoiceState _state = VoiceState.idle;
  String? _audioPath;
  int _recordingSeconds = 0; // count-up: no 15s limit, open-ended
  bool _isSilent = false;
  List<double> _amplitudeHistory = List.filled(30, 0.0);

  Timer? _timer;
  StreamSubscription<double>? _amplitudeSub;

  VoiceState get state => _state;
  String? get audioPath => _audioPath;
  int get recordingSeconds => _recordingSeconds;
  bool get isSilent => _isSilent;
  List<double> get amplitudeHistory => _amplitudeHistory;
  bool get hasRecording => _audioPath != null;

  static const Map<String, Map<String, String>> categoryAnchors = {
    'apparel': {
      'hi': 'माइक दबाकर बताएं: यह कौनसा कपड़ा है, इसमें क्या काम या ज़री है, और बनाने में कितने दिन लगे?',
      'en': 'Speak into mic: What fabric is this, what work or zari does it have, and how many days to craft?',
    },
    'pottery': {
      'hi': 'माइक दबाकर बताएं: यह मिट्टी का है या सेरामिक, इसका उपयोग क्या है, और कितने दिन में बना?',
      'en': 'Speak into mic: Is it clay or ceramic, what is its use, and how many days to make?',
    },
    'wood_metal': {
      'hi': 'माइक दबाकर बताएं: कौनसी लकड़ी या धातु का बना है, और इसे बनाने में कितना समय लगा?',
      'en': 'Speak into mic: Which wood or metal is it made of, and how much time did it take to make?',
    },
    'food': {
      'hi': 'माइक दबाकर बताएं: इस पैकेट में क्या है, इसका वज़न कितना है, और कब तक ताज़ा रहेगा?',
      'en': 'Speak into mic: What is in this packet, what is its net weight, and how long stays fresh?',
    },
    'fallback': {
      'hi': 'माइक दबाकर 2 बातें बताएं: इस वस्तु का नाम क्या है, और यह किस चीज़ से बनी है?',
      'en': 'Speak into mic 2 things: What is the name of this craft, and what material is it made from?',
    },
  };

  static String getAnchorPrompt(String category, {String lang = 'hi'}) {
    final entry = categoryAnchors[category] ?? categoryAnchors['fallback']!;
    return entry[lang] ?? entry['hi']!;
  }

  Future<void> toggleRecording() async {
    if (_state == VoiceState.idle) {
      await _startRecording();
    } else if (_state == VoiceState.recording) {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    _state = VoiceState.recording;
    _recordingSeconds = 0;
    _isSilent = false;
    _audioPath = null;
    _amplitudeHistory = List.filled(30, 0.0);
    HapticFeedback.mediumImpact();
    notifyListeners();

    final amplitudeStream = await _audioService.startRecording();

    _amplitudeSub = amplitudeStream.listen((dbfs) {
      final normalized = ((dbfs + 60) / 60).clamp(0.0, 1.0);
      _amplitudeHistory = [..._amplitudeHistory.skip(1), normalized];
      _isSilent = dbfs < AppConstants.silenceAmplitudeThreshold;
      notifyListeners();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      notifyListeners();
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;

    _audioPath = await _audioService.stopRecording();
    _state = VoiceState.stopped;
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _state = VoiceState.idle;
    _audioPath = null;
    _recordingSeconds = 0;
    _isSilent = false;
    _amplitudeHistory = List.filled(30, 0.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
