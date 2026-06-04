import 'package:flutter/material.dart';

/// Hard-coded readable colors for settings (no dependency on ColorScheme.primary for text).
abstract final class SettingsColors {
  static bool isDark(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF12151C) : const Color(0xFFF4F6F9);

  static Color cardBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C212B) : Colors.white;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFE8EAED) : const Color(0xFF1A1D26);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF9AA3B2) : const Color(0xFF5C6578);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF2D3548) : const Color(0xFFE2E8F0);

  static Color accentBlue(BuildContext context) =>
      isDark(context) ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);

  static Color accentTeal(BuildContext context) =>
      isDark(context) ? const Color(0xFF4DB6AC) : const Color(0xFF00897B);

  static Color selectedTileBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E3A5F) : const Color(0xFFD6E4F7);

  static Color selectedTileText(BuildContext context) =>
      isDark(context) ? const Color(0xFFE8EAED) : const Color(0xFF0D2D5E);

  static Color unselectedTileBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF232936) : const Color(0xFFF0F2F5);

  static Color inputFill(BuildContext context) =>
      isDark(context) ? const Color(0xFF181C24) : const Color(0xFFFAFBFC);
}
