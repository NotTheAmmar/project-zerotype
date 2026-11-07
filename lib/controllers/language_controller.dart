import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageOption {
  final String code;
  final String nativeName;
  final String englishName;

  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.englishName,
  });
}

class LanguageController extends ChangeNotifier {
  static const String _prefKey = 'bazaarsetu_user_language';
  static const String _prefSetupKey = 'bazaarsetu_language_setup_done';

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'hi', nativeName: 'हिंदी', englishName: 'Hindi'),
    LanguageOption(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    LanguageOption(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    LanguageOption(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    LanguageOption(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
    LanguageOption(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    LanguageOption(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
  ];

  String _currentLanguageCode = 'hi';
  bool _isLanguageSetupDone = false;
  bool _isLoaded = false;

  String get currentLanguageCode => _currentLanguageCode;
  bool get isLanguageSetupDone => _isLanguageSetupDone;
  bool get isLoaded => _isLoaded;

  LanguageOption get currentLanguage =>
      supportedLanguages.firstWhere(
        (l) => l.code == _currentLanguageCode,
        orElse: () => supportedLanguages.first,
      );

  LanguageController() {
    loadLanguagePreference();
  }

  Future<void> loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguageCode = prefs.getString(_prefKey) ?? 'hi';
      _isLanguageSetupDone = prefs.getBool(_prefSetupKey) ?? false;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[LanguageController] Error loading language preference: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    _currentLanguageCode = code;
    _isLanguageSetupDone = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
      await prefs.setBool(_prefSetupKey, true);
    } catch (e) {
      debugPrint('[LanguageController] Error saving language preference: $e');
    }
  }
}
