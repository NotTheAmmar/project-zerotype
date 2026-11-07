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
  });
}
