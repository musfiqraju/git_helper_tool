import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/terminal_line.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import 'common/empty_state.dart';
import 'common/panel_header.dart';

class LiveTerminalPanel extends StatefulWidget {
  const LiveTerminalPanel({
    super.key,
    required this.lines,
    required this.isRunning,
    this.onClear,
  });

  final List<TerminalLine> lines;
  final bool isRunning;
  final VoidCallback? onClear;

  @override
  State<LiveTerminalPanel> createState() => _LiveTerminalPanelState();
}

class _LiveTerminalPanelState extends State<LiveTerminalPanel> {
  final ScrollController _scrollController = ScrollController();
  int _lastLineCount = 0;

  @override
  void didUpdateWidget(LiveTerminalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lines.length > _lastLineCount) {
      _lastLineCount = widget.lines.length;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.terminalBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          PanelHeader(
            invert: true,
            icon: Icons.terminal_rounded,
            title: widget.isRunning ? 'Live output' : 'Output',
            subtitle: widget.isRunning ? 'Running batch command…' : 'Idle',
            trailing: widget.onClear != null && !widget.isRunning
                ? TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: widget.onClear,
                    child: const Text('Clear'),
                  )
                : null,
          ),
          Expanded(
            child: ClipRect(
              child: widget.lines.isEmpty
                ? const AppEmptyState(
                    icon: Icons.output_outlined,
                    title: 'No output yet',
                    message: 'Run a batch command to stream logs here.',
                    compact: true,
                  )
                : Scrollbar(
                    thumbVisibility: widget.lines.length > 20,
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      itemCount: widget.lines.length,
                      itemBuilder: (context, index) {
                        return _TerminalLineWidget(line: widget.lines[index]);
                      },
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalLineWidget extends StatelessWidget {
  const _TerminalLineWidget({required this.line});

  final TerminalLine line;

  @override
  Widget build(BuildContext context) {
    final color = switch (line.kind) {
      TerminalLineKind.info => Colors.white54,
      TerminalLineKind.command => const Color(0xFF82AAFF),
      TerminalLineKind.stdout => const Color(0xFFD4D4D4),
      TerminalLineKind.stderr => const Color(0xFFF48771),
      TerminalLineKind.success => const Color(0xFF89D185),
      TerminalLineKind.error => const Color(0xFFF48771),
      TerminalLineKind.skipped => Colors.orangeAccent,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText(
        line.text,
        maxLines: null,
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 12,
          height: 1.4,
          color: color,
        ),
      ),
    );
  }
}
