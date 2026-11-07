import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../controllers/language_controller.dart';

/// Renders English text primarily, with the local language translation
/// displayed cleanly right underneath it.
class BilingualText extends StatelessWidget {
  final String english;
  final String? local;
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
    this.englishStyle,
    this.localStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.maxLines,
    this.overflow,
    this.spacing = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final langCtrl = context.watch<LanguageController>();
    final showLocal = local != null &&
        local!.trim().isNotEmpty &&
        local!.trim() != english.trim() &&
        langCtrl.currentLanguageCode != 'en';

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          english,
          style: englishStyle ?? AppTextStyles.label,
          maxLines: maxLines,
          overflow: overflow,
        ),
        if (showLocal) ...[
          SizedBox(height: spacing),
          Text(
            local!,
            style: localStyle ??
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
