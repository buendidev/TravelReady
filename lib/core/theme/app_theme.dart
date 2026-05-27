import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Tema visual de TravelReady!
/// Sistema de diseño: "The Curated Navigator" — Soft Minimalism + Glassmorphism
abstract final class AppTheme {
  // ────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ────────────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.primaryLight,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surfaceLight,
          onSurface: AppColors.textPrimaryLight,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: _buildTextTheme(Brightness.light),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundLight,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primaryLight,
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            shape: const StadiumBorder(),
            elevation: 0,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            shape: const StadiumBorder(),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevatedLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppColors.textHintLight,
          ),
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppColors.textSecondaryLight,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceLight,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceElevatedLight,
          selectedColor: AppColors.primary.withOpacity(0.15),
          labelStyle: GoogleFonts.beVietnamPro(fontSize: 13),
          shape: const StadiumBorder(),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent, // Regla: sin líneas separadoras
          thickness: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.glassLight,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondaryLight,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );

  // ────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ────────────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryDark,
          onPrimaryContainer: Colors.white,
          secondary: AppColors.primaryLight,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.textPrimaryDark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: _buildTextTheme(Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            shape: const StadiumBorder(),
            elevation: 0,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryLight,
            minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            shape: const StadiumBorder(),
            side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevatedDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppColors.textHintDark,
          ),
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppColors.textSecondaryDark,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surfaceDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          margin: EdgeInsets.zero,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceElevatedDark,
          selectedColor: AppColors.primaryLight.withOpacity(0.2),
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: AppColors.textPrimaryDark,
          ),
          shape: const StadiumBorder(),
          side: BorderSide.none,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          thickness: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.glassDark,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: AppColors.textSecondaryDark,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );

  // ────────────────────────────────────────────────────────────────────────
  // TEXT THEME COMPARTIDO
  // ────────────────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary =
        isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark;
    final secondary =
        isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark;

    return TextTheme(
      // Plus Jakarta Sans — titulares y headings
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 36, fontWeight: FontWeight.w700, color: primary),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 30, fontWeight: FontWeight.w700, color: primary),
      displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: primary),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: primary),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: primary),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: primary),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: secondary),
      // Be Vietnam Pro — cuerpo de texto
      bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 16, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 14, fontWeight: FontWeight.w400, color: primary),
      bodySmall: GoogleFonts.beVietnamPro(
          fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14, fontWeight: FontWeight.w500, color: primary),
      labelMedium: GoogleFonts.beVietnamPro(
          fontSize: 12, fontWeight: FontWeight.w500, color: secondary),
      labelSmall: GoogleFonts.beVietnamPro(
          fontSize: 11, fontWeight: FontWeight.w400, color: secondary),
    );
  }
}
