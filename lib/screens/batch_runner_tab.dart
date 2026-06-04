import 'package:flutter/material.dart';

import '../models/repo_entry.dart';
import '../models/run_history_entry.dart';
import '../models/terminal_line.dart';
import '../services/config_store.dart';
import '../services/git_command_runner.dart';
import '../services/run_history_store.dart';
import '../utils/grid_columns.dart';
import '../utils/grid_tile_extent.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_snackbar.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/info_banner.dart';
import '../widgets/live_terminal_panel.dart';
import '../widgets/repo_grid_card.dart';
import '../widgets/resizable_panel_layout.dart';
import 'report_screen.dart';

/// Tab 1: batch run across all repos (original home UI body).
class BatchRunnerTab extends StatefulWidget {
  const BatchRunnerTab({
    super.key,
    required this.store,
    required this.historyStore,
    required this.onRelink,
  });

  final ConfigStore store;
  final RunHistoryStore historyStore;
  final Future<void> Function(RepoEntry repo) onRelink;

  @override
  State<BatchRunnerTab> createState() => BatchRunnerTabState();
}

class BatchRunnerTabState extends State<BatchRunnerTab> {
  final GitCommandRunner _runner = GitCommandRunner();
  final ScrollController _gridScrollController = ScrollController();
  final List<TerminalLine> _terminalLines = [];
  bool _running = false;
  String? _completionMessage;
  bool _completionIsSuccess = true;

  @override
  void dispose() {
    _gridScrollController.dispose();
    super.dispose();
  }

  void _appendTerminal(TerminalLine line) {
    setState(() => _terminalLines.add(line));
  }

  Future<void> _editCommand(RepoEntry repo) async {
    final controller = TextEditingController(
      text: repo.customCommand ?? '',
    );
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Command for ${repo.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Leave empty to use the global default:\n'
              '${widget.store.config.defaultCommand}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Custom command (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (repo.customCommand != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'default'),
              child: const Text('Use default'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == null) {
      controller.dispose();
      return;
    }

    String? custom;
    if (action == 'default') {
      custom = null;
    } else {
      final text = controller.text.trim();
      custom = text.isEmpty ? null : text;
    }
    controller.dispose();

    await widget.store.updateRepoCommand(repo.id, custom);
    if (mounted) setState(() {});
  }

  Future<void> _confirmRemove(RepoEntry repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove repository?'),
        content: Text('Remove "${repo.displayName}" from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.removeRepo(repo.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> runAll() async {
    final config = widget.store.config;
    if (config.runnableCount == 0) return;

    final startedAt = DateTime.now();
    final runId = widget.historyStore.newRunId();

    setState(() {
      _running = true;
      _completionMessage = null;
      _terminalLines.clear();
    });

    final results = await _runner.runAll(
      config,
      onLine: _appendTerminal,
    );

    final finishedAt = DateTime.now();
    final ok = results.where((r) => r.success).length;
    final failed = results.length - ok;
    final allOk = failed == 0;

    await widget.historyStore.addRun(
      RunHistoryEntry(
        id: runId,
        startedAt: startedAt,
        finishedAt: finishedAt,
        defaultCommand: config.defaultCommand,
        runMode: config.runMode.name,
        results: results,
      ),
    );

    if (!mounted) return;

    final message = 'Task finished: $ok succeeded, $failed failed';
    setState(() {
      _running = false;
      _completionMessage = message;
      _completionIsSuccess = allOk;
    });

    _showTaskCompleteNotification(message, allOk: allOk);
  }

  void _showTaskCompleteNotification(String message, {required bool allOk}) {
    showAppSnackBar(
      context,
      message: message,
      duration: const Duration(seconds: 8),
      isSuccess: allOk,
      isError: !allOk,
      action: SnackBarAction(
        label: 'Report',
        onPressed: openReport,
      ),
    );
  }

  void openReport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReportScreen(
          historyStore: widget.historyStore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.store.config;
    final repos = config.repos;
    final canRun = config.runnableCount > 0 && !_running;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch command',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          config.defaultCommand,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontFamily: 'Consolas'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${config.runMode.label} · '
                          '${config.runnableCount} of ${repos.length} ready',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: canRun ? runAll : null,
                    icon: _running
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: Text(_running ? 'Running…' : 'Run all'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_completionMessage != null && !_running)
          InfoBanner(
            message: _completionMessage!,
            variant: _completionIsSuccess
                ? InfoBannerVariant.success
                : InfoBannerVariant.warning,
            actionLabel: 'Report',
            onAction: openReport,
            onDismiss: () => setState(() => _completionMessage = null),
          ),
        Expanded(
          child: ResizablePanelLayout(
            key: ValueKey(config.panelLayout),
            layout: config.panelLayout,
            initialTerminalRatio: config.terminalPanelRatio,
            onRatioChanged: widget.store.updateTerminalPanelRatio,
            grid: repos.isEmpty
                ? _buildEmptyReposPlaceholder(context)
                : _buildScrollableRepoGrid(repos),
            terminal: LiveTerminalPanel(
              lines: _terminalLines,
              isRunning: _running,
              onClear: _terminalLines.isEmpty
                  ? null
                  : () => setState(() {
                        _terminalLines.clear();
                        _completionMessage = null;
                      }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReposPlaceholder(BuildContext context) {
    return const SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 280,
        child: AppEmptyState(
          icon: Icons.folder_open_outlined,
          title: 'No repositories enlisted',
          message:
              'Use Add folder to enlist git projects from any location. '
              'They remain saved until you remove or re-link them.',
        ),
      ),
    );
  }

  Widget _buildScrollableRepoGrid(List<RepoEntry> repos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final columns = gridColumnsForWidth(constraints.maxWidth);
        final cellWidth = cellWidthForGrid(
          gridWidth: constraints.maxWidth,
          columns: columns,
        );
        final titleStyle = theme.textTheme.titleSmall!.copyWith(
          fontWeight: FontWeight.w600,
        );
        final pathStyle = theme.textTheme.bodySmall!.copyWith(
          fontSize: 11,
          height: 1.35,
        );
        final tileExtent = gridTileExtentForRepos(
          cellWidth: cellWidth,
          repos: repos,
          titleStyle: titleStyle,
          pathStyle: pathStyle,
        );
        return Scrollbar(
          controller: _gridScrollController,
          thumbVisibility: repos.length > columns,
          child: GridView.builder(
            controller: _gridScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            primary: false,
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: tileExtent,
            ),
            itemCount: repos.length,
            itemBuilder: (context, index) {
              final repo = repos[index];
              return RepoGridCard(
                repo: repo,
                isRunning: _running && repo.isRunnable,
                onEditCommand: () => _editCommand(repo),
                onRelink: () => widget.onRelink(repo),
                onRemove: () => _confirmRemove(repo),
              );
            },
          ),
        );
      },
    );
  }
}

