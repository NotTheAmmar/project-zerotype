import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/constants.dart';
import '../services/audio_service.dart';

enum VoiceState { idle, recording, stopped }

class GuidedVoiceStep {
  final String key;
  final String titleHi;
  final String titleEn;
  final String questionHi;
  final String questionEn;
  final String hintHi;

  const GuidedVoiceStep({
    required this.key,
    required this.titleHi,
    required this.titleEn,
    required this.questionHi,
    required this.questionEn,
    required this.hintHi,
  });
}

class VoiceController extends ChangeNotifier {
  final AudioService _audioService;

  VoiceController({required this._audioService});

  VoiceState _state = VoiceState.idle;
  String? _audioPath;
  int _recordingSeconds = 0;
  bool _isSilent = false;
  List<double> _amplitudeHistory = List.filled(30, 0.0);

  Timer? _timer;
  StreamSubscription<double>? _amplitudeSub;

  // ── Multi-Step Guided Interview State ───────────────────────────────────────
  int _currentStep = 0;
  final Map<int, String> _stepAudioPaths = {};
  final Map<int, String> _stepTranscripts = {};

  // ── Manual UI dimensions / ONDC measures ────────────────────────────────────
  String _manualLength = '';
  String _manualWidth = '';
  String _manualHeight = '';
  String _manualUnit = 'cm'; // 'cm', 'inch', 'meter', 'g', 'kg'
  String _manualQuantity = '1 unit';

  static const List<GuidedVoiceStep> guidedSteps = [
    GuidedVoiceStep(
      key: 'name',
      titleHi: 'उत्पाद का नाम',
      titleEn: 'Craft Name',
      questionHi: 'इस हस्तशिल्प उत्पाद का क्या नाम है? (जैसे: चंदेरी सिल्क साड़ी, या पीतल की घंटी)',
      questionEn: 'What is the name and type of this handcrafted product?',
      hintHi: 'माइक दबाकर उत्पाद का नाम बताएं',
    ),
    GuidedVoiceStep(
      key: 'material',
      titleHi: 'सामग्री एवं कारीगरी',
      titleEn: 'Materials & Craft',
      questionHi: 'यह किस सामग्री से बना है और क्या खास काम है? (जैसे: शुद्ध रेशम, ज़री का काम, या मिट्टी)',
      questionEn: 'What materials are used and what is the crafting technique?',
      hintHi: 'सामग्री और बनाने का तरीका बताएं',
    ),
    GuidedVoiceStep(
      key: 'pricing',
      titleHi: 'कीमत एवं लागत',
      titleEn: 'Price & Labor',
      questionHi: 'आप इसे कितने रुपये में बेचना चाहते हैं, कच्चा माल कितने का पड़ा, और कितने दिन लगे?',
      questionEn: 'What is your selling price, raw material cost, and days of labor to make it?',
      hintHi: 'विक्रय मूल्य, लागत और समय बताएं',
    ),
    GuidedVoiceStep(
      key: 'dimensions',
      titleHi: 'माप एवं वज़न',
      titleEn: 'Dimensions & Measure',
      questionHi: 'इसकी लंबाई, चौड़ाई या वज़न कितना है? (बोलें या नीचे दिए गए बॉक्स में भी चुन सकते हैं)',
      questionEn: 'What are the dimensions or weight? (Speak or choose below)',
      hintHi: 'लंबाई, चौड़ाई या वज़न बताएं',
    ),
  ];

  static const Map<String, Map<String, String>> categoryAnchors = {
    'apparel': {
      'hi': 'माइक दबाकर बताएं: यह कौनसा कपड़ा है, इसमें क्या काम या ज़री है, और बनाने में कितने दिन लगे?',
      'en': 'Speak into mic: What fabric is this, what embroidery/zari work is done, and how many days to make?',
    },
    'pottery': {
      'hi': 'माइक दबाकर बताएं: यह किस मिट्टी से बना है, क्या रंग/पॉलिश की गई है, और क्या यह पक्की मिट्टी है?',
      'en': 'Speak into mic: What clay or ceramic is this made of, what finish or glaze, and is it kiln-fired?',
    },
    'wood_metal': {
      'hi': 'माइक दबाकर बताएं: यह कौनसी लकड़ी या धातु (पीतल/तांबा) है, और इस पर क्या नक्काशी की गई है?',
      'en': 'Speak into mic: What type of wood or metal (brass/copper) is this, and what carving is done?',
    },
    'food': {
      'hi': 'माइक दबाकर बताएं: इस पैकेट का वज़न क्या है, क्या सामग्री (इंग्रीडिएंट्स) हैं, और कब तक खराब नहीं होगा?',
      'en': 'Speak into mic: What is the packet weight, what are the ingredients, and what is the shelf life?',
    },
    'fallback': {
      'hi': 'माइक दबाकर 2 बातें बताएं: 1. यह क्या वस्तु है और किस काम आती है? 2. यह किस सामग्री से बनी है?',
      'en': 'Speak into mic 2 things: 1. What is this item and what is its use? 2. What materials is it made of?',
    },
  };

  static String getAnchorPrompt(String category, {String lang = 'hi'}) {
    final catData = categoryAnchors[category] ?? categoryAnchors['fallback']!;
    return catData[lang] ?? catData['hi']!;
  }

  VoiceState get state => _state;
  String? get audioPath => _audioPath ?? (_stepAudioPaths.isNotEmpty ? _stepAudioPaths.values.first : null);
  int get recordingSeconds => _recordingSeconds;
  bool get isSilent => _isSilent;
  List<double> get amplitudeHistory => _amplitudeHistory;
  bool get hasRecording => _audioPath != null || _stepAudioPaths.isNotEmpty;

  int get currentStep => _currentStep;
  int get totalSteps => guidedSteps.length;
  GuidedVoiceStep get currentStepData => guidedSteps[_currentStep];
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == guidedSteps.length - 1;
  Map<int, String> get stepAudioPaths => _stepAudioPaths;
  Map<int, String> get stepTranscripts => _stepTranscripts;
  bool get isCurrentStepRecorded => _stepAudioPaths.containsKey(_currentStep);

  String get manualLength => _manualLength;
  String get manualWidth => _manualWidth;
  String get manualHeight => _manualHeight;
  String get manualUnit => _manualUnit;
  String get manualQuantity => _manualQuantity;

  void setManualDimensions({
    String? length,
    String? width,
    String? height,
    String? unit,
    String? quantity,
  }) {
    if (length != null) _manualLength = length;
    if (width != null) _manualWidth = width;
    if (height != null) _manualHeight = height;
    if (unit != null) _manualUnit = unit;
    if (quantity != null) _manualQuantity = quantity;
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < guidedSteps.length - 1) {
      _currentStep++;
      _recordingSeconds = 0;
      _state = VoiceState.idle;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _recordingSeconds = 0;
      _state = VoiceState.idle;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void jumpToStep(int step) {
    if (step >= 0 && step < guidedSteps.length) {
      _currentStep = step;
      _recordingSeconds = 0;
      _state = VoiceState.idle;
      HapticFeedback.selectionClick();
      notifyListeners();
    }
  }

  void setStepTranscript(int step, String transcript) {
    _stepTranscripts[step] = transcript;
    notifyListeners();
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

    final recorded = await _audioService.stopRecording();
    _state = VoiceState.stopped;
    if (recorded != null) {
      _audioPath = recorded;
      _stepAudioPaths[_currentStep] = recorded;
    }
    HapticFeedback.lightImpact();
    notifyListeners();
  }

  void clearCurrentStepAudio() {
    _stepAudioPaths.remove(_currentStep);
    _audioPath = _stepAudioPaths.isNotEmpty ? _stepAudioPaths.values.first : null;
    _state = VoiceState.idle;
    _recordingSeconds = 0;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _state = VoiceState.idle;
    _audioPath = null;
    _recordingSeconds = 0;
    _isSilent = false;
    _currentStep = 0;
    _stepAudioPaths.clear();
    _stepTranscripts.clear();
    _manualLength = '';
    _manualWidth = '';
    _manualHeight = '';
    _manualUnit = 'cm';
    _manualQuantity = '1 unit';
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
