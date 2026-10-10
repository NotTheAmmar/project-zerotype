import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm Tactile Craft design palette
class AppColors {
  AppColors._();

  // Canvas & Surfaces
  static const Color warmCream = Color(0xFFFFF8ED);
  static const Color surfaceLight = Color(0xFFFFF8ED);
  static const Color surfaceClean = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFFEEAE0);
  static const Color surfaceContainerLow = Color(0xFFFFF1EB);
  static const Color surfaceDark = Color(0xFF231914);

  // Brand Palette
  static const Color primaryTeal = Color(0xFF176B6B);
  static const Color primaryDark = Color(0xFF005252);
  static const Color primaryContainer = Color(0xFFE6F3F3);
  static const Color secondaryTerracotta = Color(0xFFB86F52);
  static const Color secondaryContainer = Color(0xFFFBECE5);
  static const Color tertiarySaffron = Color(0xFFE3A24B);
  static const Color saffronContainer = Color(0xFFFEF3DE);

  // Status & Actions
  static const Color actionGreen = Color(0xFF176B6B);
  static const Color actionGreenLight = Color(0xFFE6F3F3);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenLight = Color(0xFFDCFCE7);
  static const Color warningAmber = Color(0xFFE3A24B);
  static const Color warningAmberLight = Color(0xFFFEF3DE);
  static const Color alertRed = Color(0xFFBA1A1A);
  static const Color alertRedLight = Color(0xFFFFDAD6);

  // Text & Neutrals (Espresso)
  static const Color textPrimary = Color(0xFF30251F);
  static const Color textSecondary = Color(0xFF6F7979);
  static const Color textMuted = Color(0xFF8C7E77);
  static const Color textHint = Color(0xFFA89F99);
  static const Color textOnDark = Color(0xFFFFF8ED);

  // Borders & Dividers
  static const Color cardBorder = Color(0x1F30251F); // ~12% opacity espresso
  static const Color borderSubtle = Color(0x1430251F);
  static const Color divider = Color(0x1230251F);
  static const Color overlay = Color(0x7030251F);

  // Legacy mappings for backwards compatibility
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color priceFloor = Color(0xFF6F7979);
  static const Color priceFair = Color(0xFF176B6B);
  static const Color pricePremium = Color(0xFFB86F52);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Touch targets
  static const double touchTargetMin = 48.0;
  static const double touchTargetPrimary = 56.0;

  // Border radii
  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 18.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Screen padding
  static const double screenH = 16.0;
  static const double screenV = 20.0;
}

class AppTextStyles {
  AppTextStyles._();

  // ── Serif Headings (Noto Serif) ───────────────────────────────────────────
  static TextStyle serifHeading({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSerif(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle serifHeadingLarge({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSerif(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.25,
      );

  static TextStyle serifTitle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSerif(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle serifSubhead({Color color = AppColors.textPrimary}) =>
      GoogleFonts.notoSerif(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.35,
      );

  // ── Standard Getters (fully backwards-compatible with .copyWith) ──────────
  static TextStyle get headline => serifHeading();
  static TextStyle get headlineLarge => serifHeadingLarge();
  static TextStyle get subhead => serifSubhead();

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.45,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  static TextStyle get buttonLabel => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get chipText => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get priceLarge => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get priceSmall => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get onDark => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textOnDark,
        height: 1.45,
      );

  // ── Parametrized helper functions ──────────────────────────────────────────
  static TextStyle bodyStyle({Color color = AppColors.textPrimary, double? height = 1.45}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: height,
      );

  static TextStyle captionStyle({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.35,
      );

  static TextStyle labelStyle({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle labelSmallStyle({Color color = AppColors.textSecondary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.3,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.warmCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        brightness: Brightness.light,
        primary: AppColors.primaryTeal,
        secondary: AppColors.secondaryTerracotta,
        tertiary: AppColors.tertiarySaffron,
        surface: AppColors.warmCream,
        error: AppColors.alertRed,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSerif(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.notoSerif(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.notoSerif(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.notoSerif(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.warmCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 0,
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonLabel,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceClean,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
    );
  }
}
