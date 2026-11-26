import 'package:flutter_test/flutter_test.dart';
import 'package:project_zerotype/controllers/language_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to Hindi if no language preference is stored', () async {
      final ctrl = LanguageController();
      await ctrl.loadLanguagePreference();

      expect(ctrl.currentLanguageCode, equals('hi'));
      expect(ctrl.isLanguageSetupDone, isFalse);
    });

    test('setLanguage updates code and persists preference', () async {
      final ctrl = LanguageController();
      await ctrl.setLanguage('mr');

      expect(ctrl.currentLanguageCode, equals('mr'));
      expect(ctrl.isLanguageSetupDone, isTrue);
      expect(ctrl.currentLanguage.nativeName, equals('मराठी'));

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('bazaarsetu_user_language'), equals('mr'));
      expect(prefs.getBool('bazaarsetu_language_setup_done'), isTrue);
    });

    test('loads saved language preference on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'bazaarsetu_user_language': 'gu',
        'bazaarsetu_language_setup_done': true,
      });

      final ctrl = LanguageController();
      await ctrl.loadLanguagePreference();

      expect(ctrl.currentLanguageCode, equals('gu'));
      expect(ctrl.isLanguageSetupDone, isTrue);
      expect(ctrl.currentLanguage.nativeName, equals('ગુજરાતી'));
    });

    test('includes all 23 Bhashini supported languages', () {
      expect(LanguageController.supportedLanguages.length, equals(23));
      final codes = LanguageController.supportedLanguages
          .map((l) => l.code)
          .toSet();
      expect(
        codes,
        containsAll(['en', 'hi', 'as', 'bn', 'brx', 'doi', 'gu', 'kn', 'ks', 'kok', 'mai', 'ml', 'mni', 'mr', 'ne', 'or', 'pa', 'sa', 'sat', 'sd', 'ta', 'te', 'ur']),
      );
    });

    test('supports single language mode and custom bilingual language pairs', () async {
      final ctrl = LanguageController(autoLoad: false);
      await ctrl.setLanguagePreferences(
        mode: LanguageDisplayMode.single,
        primaryCode: 'ta',
      );
      expect(ctrl.displayMode, equals(LanguageDisplayMode.single));
      expect(ctrl.isBilingual, isFalse);
      expect(ctrl.primaryLanguageCode, equals('ta'));
      expect(ctrl.secondaryLanguageCode, isNull);
      expect(ctrl.headerBadgeLabel, equals('தமிழ்'));

      await ctrl.setLanguagePreferences(
        mode: LanguageDisplayMode.bilingual,
        primaryCode: 'mr',
        secondaryCode: 'gu',
      );
      expect(ctrl.displayMode, equals(LanguageDisplayMode.bilingual));
      expect(ctrl.isBilingual, isTrue);
      expect(ctrl.primaryLanguageCode, equals('mr'));
      expect(ctrl.secondaryLanguageCode, equals('gu'));
      expect(ctrl.headerBadgeLabel, equals('मराठी + ગુજરાતી'));
    });
  });
}
