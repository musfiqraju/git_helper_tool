import 'package:flutter/material.dart';

import '../models/command_result.dart';
import '../models/run_history_entry.dart';
import '../services/run_history_store.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/status_badge.dart';

enum _HistoryFilter { all, success, failed }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.historyStore});

  final RunHistoryStore historyStore;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;
  String? _expandedRunId;

  List<RunHistoryEntry> get _filteredEntries {
    final all = widget.historyStore.entries;
    return switch (_filter) {
      _HistoryFilter.all => all,
      _HistoryFilter.success => all.where((e) => e.allSucceeded).toList(),
      _HistoryFilter.failed => all.where((e) => e.failCount > 0).toList(),
    };
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This permanently removes all saved run reports from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear history'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.historyStore.clearAll();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    final theme = Theme.of(context);
    final total = widget.historyStore.entries.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run history'),
        actions: [
          if (total > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear history',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Text(
              total == 0
                  ? 'Completed batch runs appear here with per-repo output.'
                  : '$total saved ${total == 1 ? 'run' : 'runs'}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<_HistoryFilter>(
              segments: const [
                ButtonSegment(
                  value: _HistoryFilter.all,
                  label: Text('All'),
                  icon: Icon(Icons.list_alt, size: 18),
                ),
                ButtonSegment(
                  value: _HistoryFilter.success,
                  label: Text('Success'),
                  icon: Icon(Icons.check_circle_outline, size: 18),
                ),
                ButtonSegment(
                  value: _HistoryFilter.failed,
                  label: Text('Failed'),
                  icon: Icon(Icons.error_outline, size: 18),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? AppEmptyState(
                    icon: widget.historyStore.entries.isEmpty
                        ? Icons.history_outlined
                        : Icons.filter_list_off_outlined,
                    title: widget.historyStore.entries.isEmpty
                        ? 'No run history yet'
                        : 'No matching runs',
                    message: widget.historyStore.entries.isEmpty
                        ? 'Run a batch command from the Batch runner tab to generate a report.'
                        : 'Try a different filter to see other runs.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _HistoryRunCard(
                        entry: entry,
                        expanded: _expandedRunId == entry.id,
                        onTap: () => setState(() {
                          _expandedRunId =
                              _expandedRunId == entry.id ? null : entry.id;
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRunCard extends StatelessWidget {
  const _HistoryRunCard({
    required this.entry,
    required this.expanded,
    required this.onTap,
  });

  final RunHistoryEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final duration = entry.finishedAt.difference(entry.startedAt);
    final allOk = entry.allSucceeded;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: allOk
                  ? scheme.secondaryContainer
                  : scheme.errorContainer.withValues(alpha: 0.5),
              child: Icon(
                allOk ? Icons.check_rounded : Icons.warning_amber_rounded,
                size: 20,
                color: allOk
                    ? scheme.onSecondaryContainer
                    : scheme.onErrorContainer,
              ),
            ),
            title: Text(
              _formatDateTime(entry.startedAt),
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  StatusBadge(
                    label: '${entry.successCount} ok',
                    tone: StatusBadgeTone.success,
                  ),
                  if (entry.failCount > 0)
                    StatusBadge(
                      label: '${entry.failCount} failed',
                      tone: StatusBadgeTone.error,
                    ),
                  StatusBadge(
                    label: entry.runMode,
                    tone: StatusBadgeTone.neutral,
                  ),
                  StatusBadge(
                    label: '${duration.inSeconds}s',
                    tone: StatusBadgeTone.neutral,
                  ),
                ],
              ),
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: scheme.onSurfaceVariant,
            ),
            onTap: onTap,
          ),
          if (expanded) ...[
            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.35)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Command',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  SelectableText(
                    entry.defaultCommand,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Consolas',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...entry.results.map((r) => _ResultSummary(result: r)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${_two(local.month)}-${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});

  final CommandResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ok = result.success;
    final tone = result.skipped
        ? StatusBadgeTone.warning
        : ok
            ? StatusBadgeTone.success
            : StatusBadgeTone.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.repoName,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              StatusBadge(
                label: result.skipped
                    ? (result.skipReason ?? 'Skipped')
                    : 'exit ${result.exitCode}',
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          SelectableText(
            result.command,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Consolas',
            ),
          ),
          if (result.stderr.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _LogBlock(
              text: result.stderr.trimRight(),
              background: scheme.errorContainer.withValues(alpha: 0.35),
            ),
          ],
          if (result.stdout.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _LogBlock(
              text: result.stdout.trimRight(),
              background: scheme.surfaceContainerHighest,
              maxLines: 10,
            ),
          ],
        ],
      ),
    );
  }
}

class _LogBlock extends StatelessWidget {
  const _LogBlock({
    required this.text,
    required this.background,
    this.maxLines,
  });

  final String text;
  final Color background;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Consolas',
              height: 1.4,
            ),
        maxLines: maxLines,
      ),
    );
  }
}
