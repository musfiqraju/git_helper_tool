import 'package:flutter/foundation.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';

/// Common interface for per-project terminal sessions in the Terminals tab.
abstract class ProjectTerminalSession extends ChangeNotifier {
  String get sessionId;
  String get repoId;
  String get displayName;
  String get shellLabel;
  bool get isRealShell;

  /// Embedded [GhosttyTerminalView] when non-null (real terminal UX).
  GhosttyTerminalController? get terminalController => null;

  bool get usesEmbeddedTerminal => terminalController != null;

  /// True when stdin is attached to a pseudo-terminal (ConPTY / POSIX PTY).
  bool get isConPty => false;

  bool get isBusy;
  String get outputText;
  bool get hasError;

  Future<void> start();
  Future<void> sendInput(String input);

  /// Write to the shell without appending a newline (PTY sessions only).
  Future<void> sendRaw(String text) async {}

  /// Write raw bytes to the PTY (PTY sessions only).
  Future<void> sendRawBytes(Uint8List bytes) async {}

  @override
  void dispose();
}
