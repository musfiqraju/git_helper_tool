import 'dart:async';

import 'package:flutter/material.dart';

import '../services/project_terminal_session.dart';
import 'embedded_terminal_pane.dart';

class ProjectTerminalView extends StatefulWidget {
  const ProjectTerminalView({
    super.key,
    required this.session,
  });

  final ProjectTerminalSession session;

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
      );
    }

    return _LineModeTerminalBody(
      session: session,
      scrollController: _scrollController,
      inputController: _inputController,
      inputFocus: _inputFocus,
      onSubmit: _submit,
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
  });

  final ProjectTerminalSession session;
  final ScrollController scrollController;
  final TextEditingController inputController;
  final FocusNode inputFocus;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TerminalHeader(session: session),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              child: SelectableText(
                session.outputText.isEmpty
                    ? 'Waiting for shell output…'
                    : session.outputText,
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFFD4D4D4),
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF252526),
              border: Border(top: BorderSide(color: Color(0xFF3C3C3C))),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
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
                  icon: const Icon(Icons.play_arrow, color: Colors.white70),
                  onPressed: session.isBusy ? null : onSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalHeader extends StatelessWidget {
  const _TerminalHeader({required this.session});

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
