import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'project_terminal_session.dart';

/// Persistent PowerShell (Windows) or bash (Unix) with live stdin/stdout.
///
/// This is a real shell process, not `cmd /c` one-shots. For full ConPTY
/// (arrow keys, PSReadLine UI) use portable_pty when SDK >= 3.10.4.
class PowershellStreamSession extends ProjectTerminalSession {
  PowershellStreamSession({
    required this.sessionId,
    required this.repoId,
    required this.displayName,
    required String initialPath,
  }) : cwd = p.normalize(p.absolute(initialPath));

  @override
  final String sessionId;
  @override
  final String repoId;
  @override
  final String displayName;
  final String cwd;

  final StringBuffer _buffer = StringBuffer();
  Process? _process;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false;
  bool _started = false;
  bool _hasError = false;

  @override
  String get shellLabel =>
      Platform.isWindows ? 'PowerShell' : 'bash';

  @override
  bool get isRealShell => true;

  @override
  bool get isBusy => false;

  @override
  String get outputText => _buffer.toString();

  @override
  bool get hasError => _hasError;

  void _append(String chunk) {
    if (_disposed || chunk.isEmpty) return;
    _buffer.write(chunk);
    notifyListeners();
  }

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    if (!Directory(cwd).existsSync()) {
      _hasError = true;
      _append('[Error] Directory does not exist:\n$cwd\n');
      return;
    }

    try {
      if (Platform.isWindows) {
        _process = await Process.start(
          'powershell.exe',
          [
            '-NoLogo',
            '-NoExit',
            '-ExecutionPolicy',
            'Bypass',
          ],
          workingDirectory: cwd,
          environment: Platform.environment,
          runInShell: false,
        );
      } else {
        _process = await Process.start(
          '/bin/bash',
          ['--noprofile', '-i'],
          workingDirectory: cwd,
          environment: Platform.environment,
          runInShell: false,
        );
      }

      _started = true;
      _listenStream(_process!.stdout, isError: false);
      _listenStream(_process!.stderr, isError: true);

      _process!.exitCode.then((code) {
        if (_disposed) return;
        _append('\n[Process exited with code $code]\n');
        notifyListeners();
      });

      _append('$shellLabel session — $displayName\n');
      _append('Directory: $cwd\n\n');
    } catch (e) {
      _hasError = true;
      _append('[Failed to start $shellLabel: $e]\n');
    }
  }

  void _listenStream(Stream<List<int>> stream, {required bool isError}) {
    final sub = stream.transform(utf8.decoder).listen(
      (data) => _append(data),
      onError: (Object e) {
        _hasError = true;
        _append(isError ? '\n[stderr error: $e]\n' : '\n[stdout error: $e]\n');
      },
    );
    _subscriptions.add(sub);
  }

  @override
  Future<void> sendInput(String input) async {
    final proc = _process;
    if (proc == null || _disposed) return;

    final line = input;
    if (line.trim().isEmpty) return;

    try {
      // PowerShell expects CRLF on Windows consoles.
      final suffix = Platform.isWindows ? '\r\n' : '\n';
      proc.stdin.write('$line$suffix');
      await proc.stdin.flush();
    } catch (e) {
      _hasError = true;
      _append('\n[Input error: $e]\n');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    final proc = _process;
    _process = null;
    if (proc != null) {
      proc.stdin.close();
      proc.kill(ProcessSignal.sigterm);
    }
    super.dispose();
  }
}
