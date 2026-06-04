import 'dart:io';

import 'package:path/path.dart' as p;

import 'interactive_shell_session.dart';
import 'project_terminal_session.dart';

/// Fallback line-based shell (one command at a time via cmd/sh).
class LineShellSession extends ProjectTerminalSession {
  LineShellSession({
    required this.sessionId,
    required this.repoId,
    required this.displayName,
    required String initialPath,
  })  : _inner = InteractiveShellSession(
          sessionId: sessionId,
          repoId: repoId,
          displayName: displayName,
          initialPath: initialPath,
        ),
        cwd = p.normalize(p.absolute(initialPath)) {
    _inner.addListener(notifyListeners);
  }

  final InteractiveShellSession _inner;
  final String cwd;

  @override
  final String sessionId;
  @override
  final String repoId;
  @override
  final String displayName;

  @override
  String get shellLabel =>
      Platform.isWindows ? 'cmd (line mode)' : 'sh (line mode)';

  @override
  bool get isRealShell => false;

  @override
  bool get isBusy => _inner.isBusy;

  @override
  String get outputText => _inner.outputLines.join('\n');

  @override
  bool get hasError => false;

  @override
  Future<void> start() => _inner.start();

  @override
  Future<void> sendInput(String input) => _inner.execute(input);

  @override
  void dispose() {
    _inner.removeListener(notifyListeners);
    _inner.dispose();
    super.dispose();
  }
}
