import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Metrics shared by [GhosttyTerminalView] so cell width matches the PTY grid.
class TerminalFontMetrics {
  TerminalFontMetrics({
    required this.fontFamily,
    required this.fontFamilyFallback,
    required this.cellWidthScale,
    required this.fontSize,
    required this.lineHeight,
  });

  final String fontFamily;
  final List<String> fontFamilyFallback;
  final double cellWidthScale;
  final double fontSize;
  final double lineHeight;

  static const double defaultFontSize = 14;
  static const double defaultLineHeight = 1;

  static TerminalFontMetrics? _cached;

  /// Loads JetBrains Mono and calibrates [cellWidthScale] to Ghostty's `W` probe.
  static Future<TerminalFontMetrics> load() async {
    final cached = _cached;
    if (cached != null) return cached;

    final fontLoader = GoogleFonts.jetBrainsMono();
    await GoogleFonts.pendingFonts([fontLoader]);
    final fontFamily = fontLoader.fontFamily;
    if (fontFamily == null) {
      return _cached = TerminalFontMetrics(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['monospace'],
        cellWidthScale: 1,
        fontSize: defaultFontSize,
        lineHeight: defaultLineHeight,
      );
    }

    final style = TextStyle(
      fontFamily: fontFamily,
      fontSize: defaultFontSize,
      height: defaultLineHeight,
    );

    _cached = TerminalFontMetrics(
      fontFamily: fontFamily,
      fontFamilyFallback: const ['monospace'],
      cellWidthScale: _calibrateCellWidthScale(style),
      fontSize: defaultFontSize,
      lineHeight: defaultLineHeight,
    );
    return _cached!;
  }

  /// Ghostty sizes the grid from `W`; widen cells to the widest common glyph so
  /// painted text does not spill into the next row at the wrong column.
  static double _calibrateCellWidthScale(TextStyle style) {
    final wPainter = TextPainter(
      text: TextSpan(text: 'W', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    if (wPainter.width <= 0) return 1.05;

    var maxWidth = wPainter.width;
    for (final probe in const ['M', '@', '#', 'm', 'w', ' ']) {
      final painter = TextPainter(
        text: TextSpan(text: probe, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) {
        maxWidth = painter.width;
      }
    }

    // Small safety margin so runs do not overflow their cell band.
    return (maxWidth / wPainter.width) * 1.02;
  }
}
