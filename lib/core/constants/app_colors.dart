import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF00D2D3);
  static const Color dark = Color(0xFF2D3436);
  static const Color grey = Color(0xFF636E72);
  static const Color light = Color(0xFFF9F9FB);
  static const Color white = Color(0xFFFFFFFF);

  static const Color primaryLight = Color(0xFFEDE9FF);
  static const Color secondaryLight = Color(0xFFE0FAFA);
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C5CE7), Color(0xFF8E7CF0)],
  );

  static const LinearGradient authHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x996C5CE7), Color(0xCC2D3436)],
  );
}
