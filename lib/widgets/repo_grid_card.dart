import 'package:flutter/material.dart';

import '../models/repo_entry.dart';

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
    final status = repo.status;
    final hasCustom =
        repo.customCommand != null && repo.customCommand!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRunning)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 2),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      repo.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
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
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit command'),
                      ),
                      PopupMenuItem(
                        value: 'relink',
                        child: Text('Re-link folder'),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _StatusChip(status: status),
                  if (hasCustom)
                    Chip(
                      label: const Text('Custom'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                repo.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.35,
                ),
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RepoStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, textColor) = switch (status) {
      RepoStatus.ok => ('OK', Colors.green, Colors.green.shade800),
      RepoStatus.missing => ('Missing', Colors.orange, Colors.orange.shade800),
      RepoStatus.notGitRepo => ('Not git', Colors.red, Colors.red.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
