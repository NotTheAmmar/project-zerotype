import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../controllers/language_controller.dart';

/// Renders text according to the user's [LanguageController] preferences:
/// - In [LanguageDisplayMode.single]: shows ONLY the user's chosen language.
/// - In [LanguageDisplayMode.bilingual]: shows the user's primary chosen language
///   with their secondary chosen language underneath.
class BilingualText extends StatelessWidget {
  final String english;
  final String? local;
  final Map<String, String>? translations;
  final TextStyle? englishStyle;
  final TextStyle? localStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final int? maxLines;
  final TextOverflow? overflow;
  final double spacing;

  const BilingualText({
    super.key,
    required this.english,
    this.local,
    this.translations,
    this.englishStyle,
    this.localStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.maxLines,
    this.overflow,
    this.spacing = 2.0,
  });

  String? _resolveText(
    LanguageController langCtrl,
    String code, {
    required bool allowFallbackToAny,
  }) {
    final fromMap = translations?[code]?.trim();
    if (fromMap != null && fromMap.isNotEmpty) return fromMap;
    if (code == 'en' && english.trim().isNotEmpty) return english;
    if (code == 'hi' && local != null && local!.trim().isNotEmpty) {
      return local;
    }

    final cachedFromEn = langCtrl.getCachedTranslation(
      english,
      targetLang: code,
    );
    if (cachedFromEn != null && cachedFromEn.isNotEmpty) return cachedFromEn;

    if (local != null && local!.trim().isNotEmpty) {
      final cachedFromHi = langCtrl.getCachedTranslation(
        local!,
        targetLang: code,
      );
      if (cachedFromHi != null && cachedFromHi.isNotEmpty) return cachedFromHi;
    }

    if (code != 'en' && code != 'hi' && english.trim().isNotEmpty) {
      langCtrl.requestTranslation(
        english,
        sourceLang: 'en',
        targetLang: code,
      );
    }

    if (!allowFallbackToAny) return null;
    if (code != 'en' && local != null && local!.trim().isNotEmpty) {
      return local;
    }
    return english.trim().isNotEmpty ? english : local;
  }

  @override
  Widget build(BuildContext context) {
    final langCtrl = context.watch<LanguageController>();
    final primaryCode = langCtrl.primaryLanguageCode;
    final secondaryCode = langCtrl.secondaryLanguageCode;

    final primaryText =
        _resolveText(langCtrl, primaryCode, allowFallbackToAny: true) ??
        english;

    String? secondaryText;
    if (langCtrl.isBilingual &&
        secondaryCode != null &&
        secondaryCode.isNotEmpty &&
        secondaryCode != primaryCode) {
      secondaryText = _resolveText(
        langCtrl,
        secondaryCode,
        allowFallbackToAny: false,
      );
      // Graceful fallback when regional text was supplied in `local` and
      // second language is a regional language without explicit Bhashini map entry.
      if ((secondaryText == null || secondaryText.trim().isEmpty) &&
          secondaryCode != 'en' &&
          local != null &&
          local!.trim().isNotEmpty &&
          local!.trim() != primaryText.trim()) {
        secondaryText = local;
      }
      if ((secondaryText == null || secondaryText.trim().isEmpty) &&
          secondaryCode == 'en' &&
          english.trim().isNotEmpty &&
          english.trim() != primaryText.trim()) {
        secondaryText = english;
      }
    }

    final showSecondary =
        langCtrl.isBilingual &&
        secondaryText != null &&
        secondaryText.trim().isNotEmpty &&
        secondaryText.trim() != primaryText.trim();

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primaryText,
          style: englishStyle ?? AppTextStyles.label,
          maxLines: maxLines,
          overflow: overflow,
        ),
        if (showSecondary) ...[
          SizedBox(height: spacing),
          Text(
            secondaryText,
            style:
                localStyle ??
                AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
            maxLines: maxLines,
            overflow: overflow,
          ),
        ],
      ],
    );
  }
}
