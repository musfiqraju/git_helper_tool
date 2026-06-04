import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/repo_entry.dart';
import '../services/config_store.dart';
import '../services/project_terminal_session.dart';
import '../services/terminal_session_factory.dart';
import '../widgets/project_terminal_view.dart';
import '../widgets/resizable_panel_layout.dart';
import '../models/panel_layout.dart';

class TerminalsWorkspaceTab extends StatefulWidget {
  const TerminalsWorkspaceTab({
    super.key,
    required this.store,
  });

  final ConfigStore store;

  @override
  State<TerminalsWorkspaceTab> createState() => _TerminalsWorkspaceTabState();
}

class _TerminalsWorkspaceTabState extends State<TerminalsWorkspaceTab> {
  final _uuid = const Uuid();
  final List<ProjectTerminalSession> _sessions = [];
  int _activeSessionIndex = 0;

  @override
  void dispose() {
    for (final s in _sessions) {
      s.dispose();
    }
    super.dispose();
  }

  void _openTerminalForRepo(RepoEntry repo) {
    if (repo.status == RepoStatus.missing) {
      _showMessage('Folder not found. Re-link the project first.');
      return;
    }
    if (repo.status == RepoStatus.notGitRepo) {
      _showMessage('This path is not a git repository.');
      return;
    }

    final existing = _sessions.indexWhere((s) => s.repoId == repo.id);
    if (existing >= 0) {
      setState(() => _activeSessionIndex = existing);
      return;
    }

    final session = TerminalSessionFactory.create(
      sessionId: _uuid.v4(),
      repoId: repo.id,
      displayName: repo.displayName,
      initialPath: repo.path,
    );

    setState(() {
      _sessions.add(session);
      _activeSessionIndex = _sessions.length - 1;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(session.start());
    });
  }

  void _closeSession(int index) {
    if (index < 0 || index >= _sessions.length) return;
    _sessions[index].dispose();
    setState(() {
      _sessions.removeAt(index);
      if (_sessions.isEmpty) {
        _activeSessionIndex = 0;
      } else if (_activeSessionIndex >= _sessions.length) {
        _activeSessionIndex = _sessions.length - 1;
      } else if (index < _activeSessionIndex) {
        _activeSessionIndex--;
      }
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repos = widget.store.config.repos;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            TerminalSessionFactory.supportsRealShell
                ? 'Double-click a project to open an interactive terminal in that folder.'
                : 'Double-click a project to open a terminal session.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ResizablePanelLayout(
            layout: PanelLayout.sideBySide,
            initialTerminalRatio: 0.68,
            minGridSize: 160,
            minTerminalSize: 280,
            grid: _ProjectListPanel(
              repos: repos,
              openRepoIds: _sessions.map((s) => s.repoId).toSet(),
              onDoubleTap: _openTerminalForRepo,
            ),
            terminal: _MultiTerminalPanel(
              sessions: _sessions,
              activeIndex: _activeSessionIndex,
              onSelect: (i) => setState(() => _activeSessionIndex = i),
              onClose: _closeSession,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectListPanel extends StatelessWidget {
  const _ProjectListPanel({
    required this.repos,
    required this.openRepoIds,
    required this.onDoubleTap,
  });

  final List<RepoEntry> repos;
  final Set<String> openRepoIds;
  final ValueChanged<RepoEntry> onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (repos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No projects enlisted.\nUse Add folder to enlist repositories.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Projects',
            style: theme.textTheme.titleSmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: repos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final repo = repos[index];
              final isOpen = openRepoIds.contains(repo.id);
              final status = repo.status;

              return Material(
                color: isOpen
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                    : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onDoubleTap: () => onDoubleTap(repo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _StatusDot(status: status),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            repo.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOpen)
                          Icon(
                            Icons.terminal,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final RepoStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RepoStatus.ok => Colors.green,
      RepoStatus.missing => Colors.orange,
      RepoStatus.notGitRepo => Colors.red,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _MultiTerminalPanel extends StatelessWidget {
  const _MultiTerminalPanel({
    required this.sessions,
    required this.activeIndex,
    required this.onSelect,
    required this.onClose,
  });

  final List<ProjectTerminalSession> sessions;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sessions.isEmpty) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.terminal_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No terminals open',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Double-click a project on the left\nto open a terminal at that folder.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = activeIndex.clamp(0, sessions.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFF2D2D2D),
          child: SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final selected = index == safeIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => onSelect(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF3C3C3C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terminal,
                            size: 14,
                            color: selected ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            session.displayName,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onClose(index),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color:
                                    selected ? Colors.white : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: ProjectTerminalView(
            key: ValueKey(sessions[safeIndex].sessionId),
            session: sessions[safeIndex],
          ),
        ),
      ],
    );
  }
}
