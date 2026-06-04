import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/terminal_line.dart';

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
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF2D2D2D),
            child: Row(
              children: [
                Icon(
                  widget.isRunning ? Icons.terminal : Icons.check_circle_outline,
                  size: 18,
                  color: widget.isRunning ? Colors.amber : Colors.greenAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isRunning ? 'Terminal — running…' : 'Terminal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                if (widget.onClear != null && !widget.isRunning)
                  TextButton(
                    onPressed: widget.onClear,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: widget.lines.isEmpty
                ? Center(
                    child: Text(
                      'Output appears here when you run commands',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.lines.length,
                    itemBuilder: (context, index) {
                      return _TerminalLineWidget(line: widget.lines[index]);
                    },
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
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 12,
          height: 1.35,
          color: color,
        ),
      ),
    );
  }
}
