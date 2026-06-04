import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Line-based interactive shell for one working directory (cd + arbitrary commands).
class InteractiveShellSession extends ChangeNotifier {
  InteractiveShellSession({
    required this.sessionId,
    required this.repoId,
    required this.displayName,
    required String initialPath,
  }) : cwd = p.normalize(p.absolute(initialPath));

  final String sessionId;
  final String repoId;
  final String displayName;
  String cwd;

  final List<String> outputLines = [];
  bool isBusy = false;
  bool disposed = false;

  void _append(String text) {
    if (disposed) return;
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (final line in normalized.split('\n')) {
      if (line.isEmpty && outputLines.isNotEmpty) continue;
      outputLines.add(line);
    }
    notifyListeners();
  }

  Future<void> start() async {
    if (!Directory(cwd).existsSync()) {
      _append('[Error] Directory does not exist:\n$cwd');
      return;
    }
    _append('Git Helper — interactive terminal');
    _append('Project: $displayName');
    _append('Working directory: $cwd');
    _append('Enter commands below (cd supported).');
    _append('');
  }

  Future<void> execute(String input) async {
    final line = input.trim();
    if (line.isEmpty || disposed) return;

    _append('> $line');
    isBusy = true;
    notifyListeners();

    try {
      if (_handleCd(line)) return;

      final result = await Process.run(
        _shellExecutable,
        _shellArgs(line),
        workingDirectory: cwd,
        runInShell: Platform.isWindows,
        environment: Platform.environment,
      );

      final out = result.stdout.toString();
      final err = result.stderr.toString();
      if (out.isNotEmpty) _append(out.trimRight());
      if (err.isNotEmpty) _append(err.trimRight());
      if (out.isEmpty && err.isEmpty && result.exitCode == 0) {
        _append('(completed)');
      } else if (result.exitCode != 0) {
        _append('[exit code ${result.exitCode}]');
      }
    } catch (e) {
      _append('[Error] $e');
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  bool _handleCd(String line) {
    final lower = line.trim().toLowerCase();
    if (lower == 'cd') {
      _append(cwd);
      return true;
    }

    final match = RegExp(r'^cd\s+(.+)$', caseSensitive: false).firstMatch(line.trim());
    if (match == null) return false;

    var target = match.group(1)!.trim();
    if ((target.startsWith('"') && target.endsWith('"')) ||
        (target.startsWith("'") && target.endsWith("'"))) {
      target = target.substring(1, target.length - 1);
    }

    final resolved = p.isAbsolute(target)
        ? p.normalize(target)
        : p.normalize(p.join(cwd, target));

    if (Directory(resolved).existsSync()) {
      cwd = resolved;
      _append('Changed directory to: $cwd');
    } else {
      _append('The system cannot find the path: $target');
    }
    return true;
  }

  static String get _shellExecutable {
    if (Platform.isWindows) return 'cmd';
    return '/bin/sh';
  }

  static List<String> _shellArgs(String command) {
    if (Platform.isWindows) return ['/c', command];
    return ['-c', command];
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
