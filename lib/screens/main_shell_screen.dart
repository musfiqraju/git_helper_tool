import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/repo_entry.dart';
import '../services/config_store.dart';
import '../services/run_history_store.dart';
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
        _showSnack('Repository added');
      case AddRepoResult.duplicate:
        _showSnack('This folder is already enlisted');
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
      _refresh();
      _showSnack('Repository re-linked');
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'not_git_repo') {
        await _showDialog(
          title: 'Not a git repository',
          message: 'The selected folder is not a git repository.',
        );
      } else if (e.message == 'duplicate') {
        _showSnack('That folder is already enlisted');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Git Helper'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_view_outlined),
              text: 'Batch runner',
            ),
            Tab(
              icon: Icon(Icons.terminal_outlined),
              text: 'Terminals',
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _openReport,
            icon: const Icon(Icons.assessment_outlined),
            label: const Text('Report'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
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
