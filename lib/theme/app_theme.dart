import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared Zenov BPO brand palette.
class AppColors {
  AppColors._();
  static const Color primary = Color(0xFF0856D9);
  static const Color primaryDark = Color(0xFF071F50);
  static const Color primarySoft = Color(0xFFE8F0FD);
  static const Color ground = Color(0xFFF4F7FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF4F7FE);
  static const Color modalGround = Color(0xFFE8F0FD);
  static const Color border = Color(0xFFD1E1FB);
  static const Color borderInput = Color(0xFF8CB4F5);
  static const Color borderDashed = borderInput;
  static const Color divider = border;
  static const Color textPrimary = Color(0xFF071F50);
  static const Color textSecondary = Color(0xFF263456);
  static const Color textMuted = textSecondary;
  static const Color textFaint = textSecondary;
  static const Color accent = primary;
  static const Color accentDark = primaryDark;
  static const Color accentSoft = primarySoft;
  static const Color success = primary;
  static const Color successSoft = primarySoft;
  static const Color warning = textSecondary;
  static const Color warningSoft = Color(0xFFE8F0FD);
  static const Color danger = primaryDark;
  static const Color dangerSoft = Color(0xFFD1E1FB);
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
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.surface,
        error: AppColors.danger,
        onError: AppColors.surface,
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
