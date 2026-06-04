import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/repo_entry.dart';
import '../services/config_store.dart';
import '../services/run_history_store.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_snackbar.dart';
import 'batch_runner_tab.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'terminals_workspace_tab.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.store,
    required this.historyStore,
  });

  final ConfigStore store;
  final RunHistoryStore historyStore;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([
      widget.store.load(),
      widget.historyStore.load(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  void _refresh() => setState(() {});

  Future<void> _pickAndAddFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a git repository folder',
    );
    if (path == null) return;

    final result = await widget.store.addRepo(path);
    if (!mounted) return;

    switch (result) {
      case AddRepoResult.added:
        _refresh();
        showAppSnackBar(context, message: 'Repository added', isSuccess: true);
      case AddRepoResult.duplicate:
        showAppSnackBar(context, message: 'This folder is already enlisted');
      case AddRepoResult.notGitRepo:
        await _showDialog(
          title: 'Not a git repository',
          message:
              'The selected folder does not contain a .git directory. '
              'Please choose the root of a git repository.',
        );
    }
  }

  Future<void> _relinkRepo(RepoEntry repo) async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Re-link repository folder',
    );
    if (path == null) return;

    try {
      await widget.store.relinkRepo(repo.id, path);
      if (!mounted) return;
      _refresh();
      showAppSnackBar(context, message: 'Repository re-linked', isSuccess: true);
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'not_git_repo') {
        await _showDialog(
          title: 'Not a git repository',
          message: 'The selected folder is not a git repository.',
        );
      } else if (e.message == 'duplicate') {
        showAppSnackBar(context, message: 'That folder is already enlisted');
      }
    }
  }

  Future<void> _showDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(
          store: widget.store,
          onSaved: _refresh,
        ),
      ),
    );
  }

  void _openReport() {
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
    if (_loading) {
      final scheme = Theme.of(context).colorScheme;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Loading workspace…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final repoCount = widget.store.config.repos.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.md,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.folder_special_outlined,
                color: scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Git Helper'),
                  Text(
                    repoCount == 0
                        ? 'No repositories enlisted'
                        : '$repoCount ${repoCount == 1 ? 'repository' : 'repositories'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          tabs: const [
            Tab(
              height: 48,
              icon: Icon(Icons.grid_view_rounded, size: 20),
              text: 'Batch runner',
            ),
            Tab(
              height: 48,
              icon: Icon(Icons.terminal_rounded, size: 20),
              text: 'Terminals',
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: OutlinedButton.icon(
              onPressed: _openReport,
              icon: const Icon(Icons.assessment_outlined, size: 18),
              label: const Text('Report'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BatchRunnerTab(
            store: widget.store,
            historyStore: widget.historyStore,
            onRelink: _relinkRepo,
          ),
          TerminalsWorkspaceTab(store: widget.store),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndAddFolder,
        icon: const Icon(Icons.add),
        label: const Text('Add folder'),
      ),
    );
  }
}
