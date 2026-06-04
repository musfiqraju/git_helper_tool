import 'package:flutter/material.dart';

import '../models/repo_entry.dart';
import '../theme/app_spacing.dart';
import 'common/status_badge.dart';

class RepoGridCard extends StatelessWidget {
  const RepoGridCard({
    super.key,
    required this.repo,
    required this.onEditCommand,
    required this.onRelink,
    required this.onRemove,
    this.isRunning = false,
  });

  final RepoEntry repo;
  final VoidCallback onEditCommand;
  final VoidCallback onRelink;
  final VoidCallback onRemove;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = repo.status;
    final hasCustom =
        repo.customCommand != null && repo.customCommand!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isRunning
              ? scheme.primary.withValues(alpha: 0.55)
              : scheme.outline.withValues(alpha: 0.5),
          width: isRunning ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {},
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight;
            final tight = maxH.isFinite && maxH < 130;
            final compact = maxH.isFinite && maxH < 155;
            final titleLines = tight ? 1 : 2;
            final pathLines = tight ? 1 : (compact ? 2 : 3);
            final showChips = !tight;

            return Padding(
              padding: EdgeInsets.all(tight ? AppSpacing.xs : AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRunning)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: AppSpacing.xs,
                            top: 2,
                          ),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          repo.displayName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Repository actions',
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEditCommand();
                            case 'relink':
                              onRelink();
                            case 'remove':
                              onRemove();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: _MenuRow(
                              icon: Icons.edit_outlined,
                              label: 'Edit command',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'relink',
                            child: _MenuRow(
                              icon: Icons.link_outlined,
                              label: 'Re-link folder',
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'remove',
                            child: _MenuRow(
                              icon: Icons.delete_outline,
                              label: 'Remove',
                              color: scheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showChips) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: [
                        StatusBadge.repo(status),
                        if (hasCustom)
                          const StatusBadge(
                            label: 'Custom cmd',
                            tone: StatusBadgeTone.info,
                          ),
                      ],
                    ),
                  ],
                  if (pathLines > 0) ...[
                    SizedBox(height: showChips ? AppSpacing.xs : AppSpacing.xxs),
                    Text(
                      repo.path,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'Consolas',
                        fontSize: 11,
                        height: 1.35,
                      ),
                      maxLines: pathLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
