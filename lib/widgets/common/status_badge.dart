import 'package:flutter/material.dart';

import '../../models/repo_entry.dart';
import '../../theme/app_spacing.dart';

/// Compact status label for repo / project rows.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
  });

  StatusBadge.repo(RepoStatus status, {super.key})
      : label = _labelFor(status),
        tone = _toneFor(status);

  final String label;
  final StatusBadgeTone tone;

  static String _labelFor(RepoStatus status) => switch (status) {
        RepoStatus.ok => 'Ready',
        RepoStatus.missing => 'Missing',
        RepoStatus.notGitRepo => 'Not a repo',
      };

  static StatusBadgeTone _toneFor(RepoStatus status) => switch (status) {
        RepoStatus.ok => StatusBadgeTone.success,
        RepoStatus.missing => StatusBadgeTone.warning,
        RepoStatus.notGitRepo => StatusBadgeTone.error,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      StatusBadgeTone.success => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      StatusBadgeTone.warning => (
          scheme.tertiaryContainer.withValues(alpha: 0.65),
          scheme.onSurface,
        ),
      StatusBadgeTone.error => (
          scheme.errorContainer,
          scheme.onErrorContainer,
        ),
      StatusBadgeTone.info => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      StatusBadgeTone.neutral => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: fg,
        ),
      ),
    );
  }
}

enum StatusBadgeTone { success, warning, error, info, neutral }
