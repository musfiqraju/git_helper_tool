import 'dart:io';

import 'ghostty_shell_session.dart';
import 'line_shell_session.dart';
import 'project_terminal_session.dart';

abstract final class TerminalSessionFactory {
  /// Prefer ConPTY / POSIX PTY on desktop; line mode as fallback.
  static ProjectTerminalSession create({
    required String sessionId,
    required String repoId,
    required String displayName,
    required String initialPath,
    bool forceLineMode = false,
  }) {
    if (!forceLineMode && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return GhosttyShellSession(
        sessionId: sessionId,
        repoId: repoId,
        displayName: displayName,
        initialPath: initialPath,
      );
    }
    return LineShellSession(
      sessionId: sessionId,
      repoId: repoId,
      displayName: displayName,
      initialPath: initialPath,
    );
  }

  static bool get supportsRealShell =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}
