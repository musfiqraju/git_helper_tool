import 'package:flutter/material.dart';

import '../models/command_result.dart';
import '../models/run_history_entry.dart';
import '../services/run_history_store.dart';

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
      _HistoryFilter.success =>
        all.where((e) => e.allSucceeded).toList(),
      _HistoryFilter.failed =>
        all.where((e) => e.failCount > 0).toList(),
    };
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This permanently removes all saved run reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run history'),
        actions: [
          if (widget.historyStore.entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear history',
              onPressed: _confirmClear,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<_HistoryFilter>(
              segments: const [
                ButtonSegment(
                  value: _HistoryFilter.all,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: _HistoryFilter.success,
                  label: Text('Success'),
                ),
                ButtonSegment(
                  value: _HistoryFilter.failed,
                  label: Text('Failed'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (s) =>
                  setState(() => _filter = s.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      widget.historyStore.entries.isEmpty
                          ? 'No run history yet.\nComplete a task to see reports here.'
                          : 'No runs match this filter.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
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
    final duration = entry.finishedAt.difference(entry.startedAt);
    final allOk = entry.allSucceeded;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              allOk ? Icons.check_circle : Icons.warning_amber,
              color: allOk ? Colors.green : Colors.orange,
            ),
            title: Text(
              _formatDateTime(entry.startedAt),
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              '${entry.successCount} ok · ${entry.failCount} failed · '
              '${entry.runMode} · ${duration.inSeconds}s',
            ),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            onTap: onTap,
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Command: ${entry.defaultCommand}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  ...entry.results.map(
                    (r) => _ResultSummary(result: r),
                  ),
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
    final ok = result.success;
    final color = result.skipped
        ? Colors.orange
        : ok
            ? Colors.green
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                result.skipped
                    ? Icons.skip_next
                    : ok
                        ? Icons.check
                        : Icons.close,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.repoName,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                result.skipped
                    ? (result.skipReason ?? 'Skipped')
                    : 'exit ${result.exitCode}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          Text(
            result.command,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'Consolas',
            ),
          ),
          if (result.stderr.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                result.stderr.trimRight(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ],
          if (result.stdout.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                result.stdout.trimRight(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'Consolas',
                ),
                maxLines: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
