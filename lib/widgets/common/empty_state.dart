import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final ultraTight = compact && maxH.isFinite && maxH < 136;
        final tight = compact && maxH.isFinite && maxH < 180;

        final outerPadding = ultraTight
            ? AppSpacing.sm
            : (compact ? AppSpacing.lg : AppSpacing.xxl);
        final iconSize = ultraTight ? 28.0 : (compact ? 40.0 : 56.0);
        final iconPad = ultraTight ? 8.0 : (compact ? 14.0 : 18.0);
        final showMessage = message != null && !ultraTight;
        final titleStyle = ultraTight
            ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(iconPad),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: scheme.primary,
              ),
            ),
            SizedBox(height: ultraTight ? AppSpacing.xs : (compact ? AppSpacing.sm : AppSpacing.md)),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: ultraTight ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
            if (showMessage) ...[
              SizedBox(height: tight ? AppSpacing.xxs : AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: tight ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ],
        );

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(outerPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
