import 'package:flutter/material.dart';

import '../services/interactive_shell_session.dart';

class InteractiveTerminalView extends StatefulWidget {
  const InteractiveTerminalView({
    super.key,
    required this.session,
  });

  final InteractiveShellSession session;

  @override
  State<InteractiveTerminalView> createState() => _InteractiveTerminalViewState();
}

class _InteractiveTerminalViewState extends State<InteractiveTerminalView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionUpdate);
  }

  @override
  void didUpdateWidget(InteractiveTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSessionUpdate);
      widget.session.addListener(_onSessionUpdate);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionUpdate);
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _submit() async {
    final text = _inputController.text;
    if (text.trim().isEmpty || widget.session.isBusy) return;
    _inputController.clear();
    await widget.session.execute(text);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Material(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF2D2D2D),
            child: Row(
              children: [
                const Icon(Icons.folder_outlined, size: 16, color: Colors.white70),
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
                        session.cwd,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontFamily: 'Consolas',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: session.outputLines.length,
              itemBuilder: (context, index) {
                final line = session.outputLines[index];
                final isPrompt = line.startsWith('>');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: SelectableText(
                    line,
                    style: TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 12,
                      height: 1.35,
                      color: isPrompt
                          ? const Color(0xFF82AAFF)
                          : const Color(0xFFD4D4D4),
                    ),
                  ),
                );
              },
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
                  r'> ',
                  style: TextStyle(
                    color: Color(0xFF82AAFF),
                    fontFamily: 'Consolas',
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocus,
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
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                IconButton(
                  tooltip: 'Run',
                  icon: const Icon(Icons.play_arrow, color: Colors.white70),
                  onPressed: session.isBusy ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
