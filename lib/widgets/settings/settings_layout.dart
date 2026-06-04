import 'package:flutter/material.dart';

/// Responsive spacing and width for settings (and similar forms).
abstract final class SettingsLayout {
  static const double maxContentWidth = 760;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1200
        ? 56.0
        : width >= 800
            ? 32.0
            : width >= 480
                ? 20.0
                : 16.0;
    final vertical = width >= 600 ? 24.0 : 16.0;
    return EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);
  }

  static double sectionGap(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 20.0 : 16.0;

  static double innerGap(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 14.0 : 12.0;

  static int optionColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 2;
    return 1;
  }
}
