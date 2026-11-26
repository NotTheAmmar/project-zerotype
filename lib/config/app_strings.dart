import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/language_controller.dart';

/// Resolves UI labels according to the user's [LanguageController] mode:
/// - In [LanguageDisplayMode.single]: returns ONLY the chosen language's text.
/// - In [LanguageDisplayMode.bilingual]: returns both chosen languages joined by [separator].
class AppStrings {
  AppStrings._();

  static String resolveForCode(
    LanguageController langCtrl,
    String code, {
    required String en,
    required String hi,
    Map<String, String>? extra,
  }) {
    final fromExtra = extra?[code]?.trim();
    if (fromExtra != null && fromExtra.isNotEmpty) return fromExtra;
    if (code == 'en') return en;
    if (code == 'hi') return hi;

    final cached = langCtrl.getCachedTranslation(en, targetLang: code);
    if (cached != null && cached.isNotEmpty) return cached;

    if (en.trim().isNotEmpty) {
      langCtrl.requestTranslation(en, sourceLang: 'en', targetLang: code);
    }
    return en;
  }

  static String pair(
    BuildContext context, {
    required String en,
    required String hi,
    Map<String, String>? extra,
    String separator = ' • ',
  }) {
    final langCtrl = context.watch<LanguageController>();
    return pairFromController(
      langCtrl,
      en: en,
      hi: hi,
      extra: extra,
      separator: separator,
    );
  }

  /// Non-listening variant for callbacks / SnackBars / event handlers.
  static String pairRead(
    BuildContext context, {
    required String en,
    required String hi,
    Map<String, String>? extra,
    String separator = ' • ',
  }) {
    final langCtrl = context.read<LanguageController>();
    return pairFromController(
      langCtrl,
      en: en,
      hi: hi,
      extra: extra,
      separator: separator,
    );
  }

  static String pairFromController(
    LanguageController langCtrl, {
    required String en,
    required String hi,
    Map<String, String>? extra,
    String separator = ' • ',
  }) {
    final primary = resolveForCode(
      langCtrl,
      langCtrl.primaryLanguageCode,
      en: en,
      hi: hi,
      extra: extra,
    );

    if (!langCtrl.isBilingual || langCtrl.secondaryLanguageCode == null) {
      return primary;
    }

    final secondary = resolveForCode(
      langCtrl,
      langCtrl.secondaryLanguageCode!,
      en: en,
      hi: hi,
      extra: extra,
    );

    if (secondary.trim().isEmpty || secondary.trim() == primary.trim()) {
      return primary;
    }
    return '$primary$separator$secondary';
  }
}
