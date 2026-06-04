import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Standard header for split panels (grid, terminal, project list).
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.dense = false,
    this.invert = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final bool dense;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final bg = invert ? const Color(0xFF252526) : scheme.surfaceContainerLow;
    final fg = invert ? Colors.white : scheme.onSurface;
    final fgMuted = invert ? Colors.white70 : scheme.onSurfaceVariant;

    final headerHeight = dense ? 40.0 : AppSpacing.panelHeaderHeight;
    final showSubtitle = subtitle != null && subtitle!.isNotEmpty && !dense;

    return Material(
      color: bg,
      child: SizedBox(
        height: headerHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgMuted),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: showSubtitle
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: fg,
                              height: 1.15,
                            ),
                          ),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: fgMuted,
                              height: 1.15,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        dense && subtitle != null && subtitle!.isNotEmpty
                            ? '$title · $subtitle'
                            : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: fg,
                          height: 1.2,
                        ),
                      ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
