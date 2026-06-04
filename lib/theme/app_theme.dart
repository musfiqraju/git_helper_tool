import 'package:flutter/material.dart';

/// Brand and surface colors for a clean developer-tool aesthetic.
abstract final class AppColors {
  static const seed = Color(0xFF0D47A1);
  static const accent = Color(0xFF00897B);
  static const surfaceLight = Color(0xFFF4F6F9);
  static const surfaceDark = Color(0xFF12151C);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1C212B);
  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF2D3548);

  // Readable text — never use primary for body copy
  static const textPrimaryLight = Color(0xFF1A1D26);
  static const textSecondaryLight = Color(0xFF5C6578);
  static const textPrimaryDark = Color(0xFFE8EAED);
  static const textSecondaryDark = Color(0xFF9AA3B2);
}

abstract final class AppTheme {
  static ThemeData light() => _base(_lightScheme(), Brightness.light);

  static ThemeData dark() => _base(_darkScheme(), Brightness.dark);

  static ColorScheme _lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1565C0),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E4F7),
      onPrimaryContainer: Color(0xFF0D2D5E),
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2DFDB),
      onSecondaryContainer: Color(0xFF004D40),
      tertiary: Color(0xFF5C6578),
      onTertiary: Colors.white,
      error: Color(0xFFC62828),
      onError: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      outlineVariant: Color(0xFFCBD5E1),
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: AppColors.textPrimaryLight,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF90CAF9),
      surfaceTint: Colors.transparent,
      surfaceContainerHighest: AppColors.cardLight,
      surfaceContainerHigh: Color(0xFFF0F2F5),
      surfaceContainer: Color(0xFFE8ECF1),
      surfaceContainerLow: Color(0xFFE2E8F0),
      surfaceContainerLowest: AppColors.cardLight,
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF64B5F6),
      onPrimary: Color(0xFF0D2137),
      primaryContainer: Color(0xFF1E3A5F),
      onPrimaryContainer: Color(0xFFD6E4F7),
      secondary: Color(0xFF4DB6AC),
      onSecondary: Color(0xFF0D2E2B),
      secondaryContainer: Color(0xFF1A3C38),
      onSecondaryContainer: Color(0xFFB2DFDB),
      tertiary: Color(0xFF9AA3B2),
      onTertiary: Color(0xFF1A1D26),
      error: Color(0xFFEF9A9A),
      onError: Color(0xFF4A0000),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: Color(0xFF3D4659),
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Color(0xFF2D3548),
      onInverseSurface: AppColors.textPrimaryDark,
      inversePrimary: Color(0xFF1565C0),
      surfaceTint: Colors.transparent,
      surfaceContainerHighest: AppColors.cardDark,
      surfaceContainerHigh: Color(0xFF232936),
      surfaceContainer: Color(0xFF1C212B),
      surfaceContainerLow: Color(0xFF181C24),
      surfaceContainerLowest: Color(0xFF141820),
    );
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.cardDark : AppColors.cardLight;

    final textTheme = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.65)),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.75)),
        helperStyle: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: scheme.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: scheme.onPrimary,
          backgroundColor: scheme.primary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(color: scheme.onSurface),
      displayMedium: TextStyle(color: scheme.onSurface),
      displaySmall: TextStyle(color: scheme.onSurface),
      headlineLarge: TextStyle(color: scheme.onSurface),
      headlineMedium: TextStyle(color: scheme.onSurface),
      headlineSmall: TextStyle(color: scheme.onSurface),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurfaceVariant,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
