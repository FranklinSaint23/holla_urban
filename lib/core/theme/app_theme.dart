import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ── Light ─────────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.light,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.light,
      cardColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.dark,
        displayColor: AppColors.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
        iconTheme: const IconThemeData(color: AppColors.dark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle:
            GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
        labelStyle:
            GoogleFonts.poppins(color: AppColors.grey, fontSize: 14),
        floatingLabelStyle: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      ),
      dividerColor: Colors.grey.shade200,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Colors.white
                : Colors.grey.shade400),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.grey.shade300),
      ),
    );
  }

  // ── Dark ──────────────────────────────────────────────────────────────
  static ThemeData get dark {
    const bgColor = Color(0xFF12121C);
    const surfaceColor = Color(0xFF1C1C2A);
    const cardColor = Color(0xFF252535);
    const textColor = Color(0xFFEAEAF0);
    const subtextColor = Color(0xFF9090A0);
    const borderColor = Color(0xFF2E2E42);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: surfaceColor,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: bgColor,
      cardColor: cardColor,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle:
            GoogleFonts.poppins(color: subtextColor, fontSize: 14),
        labelStyle:
            GoogleFonts.poppins(color: subtextColor, fontSize: 14),
        floatingLabelStyle: GoogleFonts.poppins(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500),
      ),
      dividerColor: borderColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? Colors.white
                : subtextColor),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? AppColors.primary
                : borderColor),
      ),
    );
  }
}

// Extension pour accéder facilement aux couleurs selon le thème
extension AppThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get cardBg => isDark ? const Color(0xFF252535) : Colors.white;
  Color get subtextColor =>
      isDark ? const Color(0xFF9090A0) : AppColors.grey;
  Color get borderColor =>
      isDark ? const Color(0xFF2E2E42) : const Color(0xFFEEEEEE);
  Color get bgColor =>
      isDark ? const Color(0xFF12121C) : AppColors.light;
  Color get surfaceColor =>
      isDark ? const Color(0xFF1C1C2A) : Colors.white;
}
