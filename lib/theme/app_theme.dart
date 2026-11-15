import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens — colors, type, radii, spacing.
/// Mirrors the Home / Dashboard / Request-Leave mockups:
/// warm neutral ground, deep teal primary, clay/orange accent.
class AppColors {
  AppColors._();

  static const Color ground = Color(0xFFFAF8F4); // page background
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surfaceAlt = Color(0xFFFCFBF8); // inputs
  static const Color modalGround = Color(0xFFEFEAE0);

  static const Color border = Color(0xFFE7E2D8);
  static const Color borderInput = Color(0xFFDCD6C8);
  static const Color borderDashed = Color(0xFFCFC7B4);
  static const Color divider = Color(0xFFF0ECE2);

  static const Color textPrimary = Color(0xFF15332D);
  static const Color textSecondary = Color(0xFF6B6456);
  static const Color textMuted = Color(0xFF9A9384);
  static const Color textFaint = Color(0xFFA49C8C);

  static const Color primary = Color(0xFF1F4D45); // deep teal
  static const Color primaryDark = Color(0xFF15332D);
  static const Color primarySoft = Color(0xFFEEF3F1);

  static const Color accent = Color(0xFFB5563C); // clay / admin + CTA
  static const Color accentDark = Color(0xFFA14B3A);
  static const Color accentSoft = Color(0xFFFBEFE8);

  static const Color success = Color(0xFF2F6B45);
  static const Color successSoft = Color(0xFFE8F1EA);
  static const Color warning = Color(0xFF9A7B1F);
  static const Color warningSoft = Color(0xFFFCF3DC);
  static const Color danger = Color(0xFFA14B3A);
  static const Color dangerSoft = Color(0xFFFBE7E4);
}

class AppRadii {
  AppRadii._();
  static const double sm = 9;
  static const double md = 11;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 18;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Breakpoints used throughout for responsive layout decisions.
class AppBreakpoints {
  AppBreakpoints._();
  static const double mobile = 600;
  static const double tablet = 1024;
  static const double desktop = 1360;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: GoogleFonts.interTextTheme(),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // Fraunces-style display font for headings/initials, matching mockup.
        displayLarge: GoogleFonts.fraunces(
          fontSize: 40,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
          letterSpacing: -0.4,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.borderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.borderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.ground,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

/// Helper used by screens/widgets to branch on available width.
enum ScreenSize { mobile, tablet, desktop }

ScreenSize screenSizeOf(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < AppBreakpoints.mobile) return ScreenSize.mobile;
  if (width < AppBreakpoints.tablet) return ScreenSize.tablet;
  return ScreenSize.desktop;
}
