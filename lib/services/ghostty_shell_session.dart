import 'dart:io';

import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';
import 'package:path/path.dart' as p;

import 'ghostty_windows_pty_bridge.dart';
import 'project_terminal_session.dart';

/// Full VT terminal session (ConPTY / PTY) via Ghostty for a project folder.
class GhosttyShellSession extends ProjectTerminalSession {
  GhosttyShellSession({
    required this.sessionId,
    required this.repoId,
    required this.displayName,
    required String initialPath,
    GhosttyTerminalController? controller,
  })  : cwd = p.normalize(p.absolute(initialPath)),
        controller = controller ??
            GhosttyTerminalController(
              preferPty: true,
              initialCols: 120,
              initialRows: 32,
              maxLines: 800,
              maxScrollback: 4000,
            );

  @override
  final String sessionId;
  @override
  final String repoId;
  @override
  final String displayName;
  final String cwd;

  final GhosttyTerminalController controller;

  GhosttyWindowsPtyBridge? _windowsPtyBridge;
  bool _started = false;
  bool _hasError = false;
  String? _startError;

  @override
  GhosttyTerminalController? get terminalController => controller;

  @override
  bool get usesEmbeddedTerminal => true;

  @override
  String get shellLabel =>
      Platform.isWindows ? 'PowerShell (terminal)' : 'bash (terminal)';

  @override
  bool get isRealShell => true;

  @override
  bool get isConPty => controller.isRunning;

  @override
  bool get isBusy => false;

  @override
  String get outputText => controller.plainText;

  @override
  bool get hasError => _hasError;

  String? get startError => _startError;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (!Directory(cwd).existsSync()) {
      _hasError = true;
      _startError = 'Directory does not exist:\n$cwd';
      controller.appendDebugOutput('[Error] $_startError\n');
      notifyListeners();
      return;
    }

    controller.addListener(_onControllerUpdate);

    try {
      final launch = _launchForDirectory(cwd);
      if (Platform.isWindows) {
        _windowsPtyBridge = GhosttyWindowsPtyBridge(controller: controller);
        await _windowsPtyBridge!.start(launch);
      } else {
        await controller.startLaunch(launch);
      }
    } catch (e) {
      _hasError = true;
      _startError = e.toString();
      controller.appendDebugOutput('[Failed to start shell: $e]\n');
      notifyListeners();
    }
  }

  void _onControllerUpdate() {
    if (hasListeners) notifyListeners();
  }

  @override
  Future<void> sendInput(String input) async {
    if (!controller.isRunning || input.trim().isEmpty) return;
    final suffix = Platform.isWindows ? '\r\n' : '\n';
    controller.write('$input$suffix');
  }

  @override
  void dispose() {
    _windowsPtyBridge?.dispose();
    _windowsPtyBridge = null;
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }
}

GhosttyTerminalShellLaunch _launchForDirectory(String cwd) {
  final environment = ghosttyTerminalShellEnvironment(
    platformEnvironment: ghosttyTerminalPlatformEnvironment(),
    overrides: const {'TERM': 'xterm-256color'},
  );

  if (Platform.isWindows) {
    return GhosttyTerminalShellLaunch(
      label: 'PowerShell',
      shell: 'powershell.exe',
      arguments: const [
        '-NoLogo',
        '-NoExit',
        '-ExecutionPolicy',
        'Bypass',
      ],
      environment: environment,
      setupCommand: _powershellCdCommand(cwd),
    );
  }

  return GhosttyTerminalShellLaunch(
    label: 'bash',
    shell: '/bin/bash',
    arguments: const ['--noprofile', '-i'],
    environment: environment,
    setupCommand: 'cd ${_shellQuote(cwd)}\n',
  );
}

String _powershellCdCommand(String path) {
  final escaped = path.replaceAll("'", "''");
  return "Set-Location -LiteralPath '$escaped'\r\n"
      r'$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()' '\r\n';
}

String _shellQuote(String path) {
  return "'${path.replaceAll("'", "'\\''")}'";
}
