import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design system for Peblo Story Buddy.
///
/// Every color, gradient, radius, and text style used across the app lives
/// here so the UI stays visually consistent and easy to retheme.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F9DFF);
  static const Color secondary = Color(0xFFFFB84D);
  static const Color accent = Color(0xFF7CDE7A);
  static const Color success = Color(0xFF00C853);
  static const Color background = Color(0xFFFFF8EE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);

  // Supporting tones derived from the core palette.
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color error = Color(0xFFFF6B6B);
  static const Color primaryDark = Color(0xFF2E7BDB);
  static const Color secondaryDark = Color(0xFFE89A2A);

  static const List<Color> heroGradient = [primary, Color(0xFF7AB8FF)];
  static const List<Color> sunnyGradient = [secondary, Color(0xFFFFD180)];
  static const List<Color> successGradient = [success, accent];
}

class AppRadii {
  AppRadii._();

  static const double card = 28.0;
  static const double button = 24.0;
  static const double chip = 18.0;
  static const double pill = 100.0;
}

class AppShadows {
  AppShadows._();

  /// Soft, diffused shadow used for cards — never harsh or "corporate".
  static List<BoxShadow> soft({Color? color}) => [
        BoxShadow(
          color: (color ?? AppColors.textPrimary).withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> button({Color? color}) => [
        BoxShadow(
          color: (color ?? AppColors.primary).withOpacity(0.35),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Builds the full [ThemeData] for the app. Always light — Peblo Story
/// Buddy intentionally has no dark theme so the experience stays bright
/// and consistent for young children.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
