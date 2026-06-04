import 'package:flutter/material.dart';

import '../models/repo_entry.dart';

/// Minimum tile height regardless of content.
const double gridTileMinExtent = 118;

/// Maximum path lines used for height estimation (avoids huge tiles).
const int gridTileMaxPathLines = 10;

/// Computes grid [mainAxisExtent] for a repo card at the given [cellWidth].
double gridTileExtentForRepo({
  required double cellWidth,
  required RepoEntry repo,
  required TextStyle titleStyle,
  required TextStyle pathStyle,
  bool hasCustomChip = false,
}) {
  const horizontalPadding = 24.0;
  const verticalPadding = 24.0;
  const menuButtonWidth = 40.0;
  const chipsBlockHeight = 28.0;
  const verticalGaps = 14.0;
  const safetyBuffer = 8.0;

  final contentWidth = (cellWidth - horizontalPadding).clamp(48.0, double.infinity);
  final titleWidth = (contentWidth - menuButtonWidth).clamp(48.0, double.infinity);

  final titleLines = _lineCountForText(
    repo.displayName,
    titleStyle,
    titleWidth,
  );
  final pathLines = _lineCountForText(
    repo.path,
    pathStyle,
    contentWidth,
  ).clamp(2, gridTileMaxPathLines);

  final titleLineHeight = _lineHeight(titleStyle);
  final pathLineHeight = _lineHeight(pathStyle);

  var extent = verticalPadding +
      titleLines * titleLineHeight +
      verticalGaps +
      chipsBlockHeight +
      (hasCustomChip ? 4.0 : 0.0) +
      verticalGaps +
      pathLines * pathLineHeight +
      safetyBuffer;

  return extent.clamp(gridTileMinExtent, 420.0);
}

double _lineHeight(TextStyle style) {
  final size = style.fontSize ?? 14.0;
  return size * (style.height ?? 1.35);
}

/// Largest extent needed for any repo in the list (uniform row height per grid).
double gridTileExtentForRepos({
  required double cellWidth,
  required List<RepoEntry> repos,
  required TextStyle titleStyle,
  required TextStyle pathStyle,
}) {
  if (repos.isEmpty) return gridTileMinExtent;

  var maxExtent = gridTileMinExtent;
  for (final repo in repos) {
    final hasCustom = repo.customCommand != null &&
        repo.customCommand!.trim().isNotEmpty;
    final extent = gridTileExtentForRepo(
      cellWidth: cellWidth,
      repo: repo,
      titleStyle: titleStyle,
      pathStyle: pathStyle,
      hasCustomChip: hasCustom,
    );
    if (extent > maxExtent) maxExtent = extent;
  }
  return maxExtent;
}

double cellWidthForGrid({
  required double gridWidth,
  required int columns,
  double horizontalPadding = 24,
  double crossAxisSpacing = 12,
}) {
  final usable = gridWidth - horizontalPadding;
  if (columns <= 1) return usable;
  return (usable - crossAxisSpacing * (columns - 1)) / columns;
}

int _lineCountForText(String text, TextStyle style, double maxWidth) {
  if (text.isEmpty) return 1;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: gridTileMaxPathLines,
  )..layout(maxWidth: maxWidth);
  return painter.computeLineMetrics().length.clamp(1, gridTileMaxPathLines);
}
