import 'package:flutter/material.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';

import '../services/project_terminal_session.dart';
import '../theme/app_theme.dart';
import 'common/panel_header.dart';
import 'terminal_font_metrics.dart';

/// Full-screen Ghostty terminal with aligned monospace grid (no separate input bar).
class EmbeddedTerminalPane extends StatefulWidget {
  const EmbeddedTerminalPane({
    super.key,
    required this.session,
    required this.controller,
    required this.focusNode,
    this.showHeader = true,
  });

  final ProjectTerminalSession session;
  final GhosttyTerminalController controller;
  final FocusNode focusNode;
  final bool showHeader;

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
      color: AppColors.terminalBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader)
            PanelHeader(
              invert: true,
              icon: Icons.terminal_rounded,
              title: widget.session.displayName,
              subtitle: widget.session.shellLabel,
            ),
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
            child: ClipRect(
              child: FutureBuilder<TerminalFontMetrics>(
              future: _metricsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white38,
                      ),
                    ),
                  );
                }
                final metrics = snapshot.data!;
                return GhosttyTerminalView(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: true,
                  backgroundColor: AppColors.terminalBackground,
                  foregroundColor: const Color(0xFFCCCCCC),
                  chromeColor: AppColors.terminalChrome,
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
          ),
        ],
      ),
    );
  }
}
