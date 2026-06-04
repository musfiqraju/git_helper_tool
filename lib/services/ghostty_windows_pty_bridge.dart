import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';

import '../utils/terminal_stream_normalize.dart';

/// Windows shell transport for [GhosttyTerminalController].
///
/// Ghostty skips native PTY on Windows; a previous ConPTY loop used blocking
/// [readSync] on the UI isolate and froze the app. This bridge uses async
/// process streams plus batched VT updates instead.
class GhosttyWindowsPtyBridge {
  GhosttyWindowsPtyBridge({required this.controller});

  final GhosttyTerminalController controller;

  Process? _process;
  StreamSubscription<List<int>>? _stdoutSub;
  StreamSubscription<List<int>>? _stderrSub;
  final BytesBuilder _pendingOutput = BytesBuilder();
  Timer? _flushTimer;
  bool _closed = false;

  Future<void> start(GhosttyTerminalShellLaunch launch) async {
    controller.attachExternalTransport(
      writeBytes: _writeBytes,
      onResize: (_, _, _, _) {
        // Piped processes do not receive SIGWINCH; VT grid still resizes locally.
      },
      launch: launch,
    );

    _process = await Process.start(
      launch.shell,
      launch.arguments,
      environment: launch.environment,
      runInShell: false,
    );

    void onChunk(List<int> chunk) {
      if (_closed || chunk.isEmpty) return;
      _pendingOutput.add(chunk);
      _scheduleFlush();
    }

    _stdoutSub = _process!.stdout.listen(
      onChunk,
      onError: (_) => _scheduleFlush(),
    );
    _stderrSub = _process!.stderr.listen(
      onChunk,
      onError: (_) => _scheduleFlush(),
    );

    unawaited(
      _process!.exitCode.then((code) {
        _flushNow();
        _handleExit(code);
      }),
    );

    final setup = launch.setupCommand;
    if (setup != null && setup.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!_closed) {
        controller.write(setup);
      }
    }
  }

  void _scheduleFlush() {
    if (_flushTimer != null || _closed) return;
    _flushTimer = Timer(const Duration(milliseconds: 32), _flushNow);
  }

  void _flushNow() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_closed || _pendingOutput.isEmpty) return;

    final chunk = _pendingOutput.toBytes();
    _pendingOutput.clear();
    controller.appendOutputBytes(normalizePipedOutputForVt(chunk));
  }

  bool _writeBytes(List<int> bytes) {
    final process = _process;
    if (process == null || _closed) return false;
    try {
      process.stdin.add(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleExit(int exitCode) {
    if (_closed) return;
    controller.appendOutputBytes(
      utf8.encode('\r\n[process exited: $exitCode]\r\n'),
    );
    controller.setSessionRunning(false);
    dispose();
  }

  void dispose() {
    if (_closed) return;
    _closed = true;

    _flushTimer?.cancel();
    _flushTimer = null;
    _flushNow();

    unawaited(_stdoutSub?.cancel());
    unawaited(_stderrSub?.cancel());
    _stdoutSub = null;
    _stderrSub = null;

    final process = _process;
    _process = null;
    if (process != null) {
      try {
        process.stdin.close();
      } catch (_) {}
      try {
        process.kill(ProcessSignal.sigterm);
      } catch (_) {}
    }

    controller.detachExternalTransport();
    controller.setSessionRunning(false);
  }
}
