import 'package:flutter/material.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';

import '../services/project_terminal_session.dart';
import 'terminal_font_metrics.dart';

/// Full-screen Ghostty terminal with aligned monospace grid (no separate input bar).
class EmbeddedTerminalPane extends StatefulWidget {
  const EmbeddedTerminalPane({
    super.key,
    required this.session,
    required this.controller,
    required this.focusNode,
  });

  final ProjectTerminalSession session;
  final GhosttyTerminalController controller;
  final FocusNode focusNode;

  @override
  State<EmbeddedTerminalPane> createState() => _EmbeddedTerminalPaneState();
}

class _EmbeddedTerminalPaneState extends State<EmbeddedTerminalPane> {
  Future<TerminalFontMetrics>? _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = TerminalFontMetrics.load();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0C0C0C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TerminalHeaderBar(session: widget.session),
          if (widget.session.hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF5C1A1A),
              child: Text(
                widget.session.outputText.contains('[Failed')
                    ? widget.session.outputText.split('\n').first
                    : 'Terminal failed to start.',
                style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 11),
              ),
            ),
          Expanded(
            child: FutureBuilder<TerminalFontMetrics>(
              future: _metricsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final metrics = snapshot.data!;
                return GhosttyTerminalView(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  backgroundColor: const Color(0xFF0C0C0C),
                  foregroundColor: const Color(0xFFCCCCCC),
                  chromeColor: const Color(0xFF1E1E1E),
                  fontSize: metrics.fontSize,
                  lineHeight: metrics.lineHeight,
                  fontFamily: metrics.fontFamily,
                  fontFamilyFallback: metrics.fontFamilyFallback,
                  cellWidthScale: metrics.cellWidthScale,
                  letterSpacing: 0,
                  palette: GhosttyTerminalPalette.xterm,
                  cursorColor: const Color(0xFFAEAFAD),
                  selectionColor: const Color(0xFF264F78),
                  hyperlinkColor: const Color(0xFF3794FF),
                  padding: EdgeInsets.zero,
                  interactionPolicy: GhosttyTerminalInteractionPolicy.auto,
                  renderer: GhosttyTerminalRendererMode.formatter,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalHeaderBar extends StatelessWidget {
  const _TerminalHeaderBar({required this.session});

  final ProjectTerminalSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF2D2D2D),
      child: Row(
        children: [
          Icon(
            session.isRealShell ? Icons.terminal : Icons.code,
            size: 16,
            color: Colors.white70,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  session.shellLabel,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (session.isBusy)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.amber,
              ),
            ),
        ],
      ),
    );
  }
}
