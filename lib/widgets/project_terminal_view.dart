import 'dart:async';

import 'package:flutter/material.dart';

import '../services/project_terminal_session.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'common/panel_header.dart';
import 'embedded_terminal_pane.dart';

class ProjectTerminalView extends StatefulWidget {
  const ProjectTerminalView({
    super.key,
    required this.session,
    this.showHeader = true,
  });

  final ProjectTerminalSession session;
  final bool showHeader;

  @override
  State<ProjectTerminalView> createState() => _ProjectTerminalViewState();
}

class _ProjectTerminalViewState extends State<ProjectTerminalView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final FocusNode _terminalFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onUpdate);
    if (widget.session.usesEmbeddedTerminal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _terminalFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(ProjectTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onUpdate);
      widget.session.addListener(_onUpdate);
      if (widget.session.usesEmbeddedTerminal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _terminalFocus.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onUpdate);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    _terminalFocus.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    // Embedded VT listens to [GhosttyTerminalController] directly; avoid
    // rebuilding this widget on every output chunk (major UI jank on Windows).
    if (widget.session.usesEmbeddedTerminal) {
      if (widget.session.hasError) {
        setState(() {});
      }
      return;
    }
    setState(() {});
    if (!widget.session.usesEmbeddedTerminal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  Future<void> _submit() async {
    final text = _inputController.text;
    if (text.trim().isEmpty || widget.session.isBusy) return;
    _inputController.clear();
    await widget.session.sendInput(text);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    if (session.usesEmbeddedTerminal) {
      return EmbeddedTerminalPane(
        session: session,
        controller: session.terminalController!,
        focusNode: _terminalFocus,
        showHeader: widget.showHeader,
      );
    }

    return _LineModeTerminalBody(
      session: session,
      scrollController: _scrollController,
      inputController: _inputController,
      inputFocus: _inputFocus,
      onSubmit: _submit,
      showHeader: widget.showHeader,
    );
  }
}

class _LineModeTerminalBody extends StatelessWidget {
  const _LineModeTerminalBody({
    required this.session,
    required this.scrollController,
    required this.inputController,
    required this.inputFocus,
    required this.onSubmit,
    required this.showHeader,
  });

  final ProjectTerminalSession session;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final FocusNode inputFocus;
  final Future<void> Function() onSubmit;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.terminalBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            PanelHeader(
              invert: true,
              icon: Icons.terminal_rounded,
              title: session.displayName,
              subtitle: session.shellLabel,
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SelectableText(
                session.outputText.isEmpty
                    ? 'Waiting for shell output…'
                    : session.outputText,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFFD4D4D4),
                ),
              ),
            ),
          ),
          Material(
            color: AppColors.terminalChrome,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Text(
                    '> ',
                    style: TextStyle(
                      color: Color(0xFF82AAFF),
                      fontFamily: 'Consolas',
                      fontSize: 13,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      focusNode: inputFocus,
                      enabled: !session.isBusy,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Consolas',
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Enter command…',
                        hintStyle: TextStyle(color: Colors.white38),
                      ),
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send (Enter)',
                    icon: const Icon(Icons.send_rounded, color: Colors.white70),
                    onPressed: session.isBusy ? null : onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
