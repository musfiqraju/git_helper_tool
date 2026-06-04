import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/panel_layout.dart';
import '../models/repo_entry.dart';
import '../services/config_store.dart';
import '../services/project_terminal_session.dart';
import '../services/terminal_session_factory.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/app_snackbar.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/info_banner.dart';
import '../widgets/common/panel_header.dart';
import '../widgets/common/status_badge.dart';
import '../widgets/project_terminal_view.dart';
import '../widgets/resizable_panel_layout.dart';

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
      showAppSnackBar(
        context,
        message: 'Folder not found. Re-link the project first.',
        isError: true,
      );
      return;
    }
    if (repo.status == RepoStatus.notGitRepo) {
      showAppSnackBar(
        context,
        message: 'This path is not a git repository.',
        isError: true,
      );
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

  @override
  Widget build(BuildContext context) {
    final repos = widget.store.config.repos;
    final openCount = _sessions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: InfoBanner(
            message: TerminalSessionFactory.supportsRealShell
                ? 'Double-click a project to open an interactive shell in that folder.'
                : 'Double-click a project to open a terminal session.',
            icon: Icons.touch_app_outlined,
            variant: InfoBannerVariant.info,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ResizablePanelLayout(
            layout: PanelLayout.sideBySide,
            initialTerminalRatio: 0.68,
            minGridSize: 200,
            minTerminalSize: 300,
            grid: _ProjectListPanel(
              repos: repos,
              openRepoIds: _sessions.map((s) => s.repoId).toSet(),
              onDoubleTap: _openTerminalForRepo,
            ),
            terminal: _MultiTerminalPanel(
              sessions: _sessions,
              activeIndex: _activeSessionIndex,
              openCount: openCount,
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
    final scheme = theme.colorScheme;

    if (repos.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: 'Projects',
            subtitle: '${repos.length} enlisted',
            icon: Icons.folder_outlined,
          ),
          const Expanded(
            child: AppEmptyState(
              icon: Icons.folder_off_outlined,
              title: 'No projects yet',
              message: 'Add folders with Add folder, then open terminals here.',
              compact: true,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelHeader(
          title: 'Projects',
          subtitle: '${repos.length} enlisted · ${openRepoIds.length} open',
          icon: Icons.folder_outlined,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: repos.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              final repo = repos[index];
              final isOpen = openRepoIds.contains(repo.id);

              return Material(
                color: isOpen
                    ? scheme.primaryContainer.withValues(alpha: 0.4)
                    : scheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: BorderSide(
                    color: isOpen
                        ? scheme.primary.withValues(alpha: 0.35)
                        : scheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onDoubleTap: () => onDoubleTap(repo),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        StatusBadge.repo(repo.status),
                        const SizedBox(width: AppSpacing.sm),
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
                            Icons.terminal_rounded,
                            size: 18,
                            color: scheme.primary,
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

class _MultiTerminalPanel extends StatelessWidget {
  const _MultiTerminalPanel({
    required this.sessions,
    required this.activeIndex,
    required this.openCount,
    required this.onSelect,
    required this.onClose,
  });

  final List<ProjectTerminalSession> sessions;
  final int activeIndex;
  final int openCount;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (sessions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            invert: true,
            title: 'Terminal',
            subtitle: 'No session',
            icon: Icons.terminal_rounded,
          ),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFF141414),
              child: AppEmptyState(
                icon: Icons.terminal_outlined,
                title: 'No terminals open',
                message:
                    'Double-click a project on the left to start a shell in that directory.',
                compact: true,
              ),
            ),
          ),
        ],
      );
    }

    final safeIndex = activeIndex.clamp(0, sessions.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: const Color(0xFF252526),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelHeader(
                invert: true,
                dense: true,
                title: 'Sessions',
                subtitle: '$openCount open',
                icon: Icons.tab_rounded,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < sessions.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: _SessionTabChip(
                          label: sessions[index].displayName,
                          selected: index == safeIndex,
                          scheme: scheme,
                          onSelect: () => onSelect(index),
                          onClose: () => onClose(index),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRect(
            child: ProjectTerminalView(
              key: ValueKey(sessions[safeIndex].sessionId),
              session: sessions[safeIndex],
              showHeader: false,
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionTabChip extends StatelessWidget {
  const _SessionTabChip({
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onSelect,
    required this.onClose,
  });

  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? scheme.onPrimary : Colors.white70;
    final fgMuted = selected ? scheme.onPrimary : Colors.white54;

    return Material(
      color: selected ? scheme.primary : const Color(0xFF3A3A3C),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal_rounded, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: fgMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
