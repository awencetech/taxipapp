import 'package:flutter/material.dart';

class AppColors {
  // TaxiNanban UI Colors (from design system)
  static const Color background = Color(0xFFF8FAFC);
  static const Color foreground = Color(0xFF111827);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF111827);
  static const Color primary = Color(0xFF111827); // Black
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF97316); // Orange
  static const Color secondaryForeground = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFF1F5F9);
  static const Color mutedForeground = Color(0xFF64748B);
  static const Color accent = Color(0xFF22C55E); // Green
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color input = Colors.transparent;
  static const Color inputBackground = Color(0xFFF1F5F9);
  static const Color ring = Color(0xFFF97316);

  // Legacy colors (for compatibility)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111827);
  static const Color error = destructive;
  static const Color success = accent;
  static const Color grey100 = muted;
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = border;
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey600 = mutedForeground;
  static const Color primaryLight = Color(0xFFFFECB3);
}
