import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Inline banner for hints, completion, or warnings.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon,
    this.variant = InfoBannerVariant.info,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final InfoBannerVariant variant;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final (Color bg, Color fg, IconData defaultIcon) = switch (variant) {
      InfoBannerVariant.success => (
          scheme.secondaryContainer.withValues(alpha: 0.55),
          scheme.onSecondaryContainer,
          Icons.check_circle_outline,
        ),
      InfoBannerVariant.warning => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100),
          Icons.warning_amber_rounded,
        ),
      InfoBannerVariant.error => (
          scheme.errorContainer.withValues(alpha: 0.5),
          scheme.onErrorContainer,
          Icons.error_outline,
        ),
      InfoBannerVariant.info => (
          scheme.primaryContainer.withValues(alpha: 0.4),
          scheme.onPrimaryContainer,
          Icons.info_outline,
        ),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = variant == InfoBannerVariant.warning && isDark
        ? const Color(0xFF3D2E14)
        : bg;
    final foreground = variant == InfoBannerVariant.warning && isDark
        ? const Color(0xFFFFB74D)
        : fg;

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon ?? defaultIcon, size: 20, color: foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(actionLabel!),
              ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(Icons.close, size: 18, color: foreground),
                onPressed: onDismiss,
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

enum InfoBannerVariant { info, success, warning, error }
