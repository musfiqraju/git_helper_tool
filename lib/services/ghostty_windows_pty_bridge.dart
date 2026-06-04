import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/scheduler.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';
import 'package:portable_pty/portable_pty.dart';

/// Windows ConPTY transport for [GhosttyTerminalController].
///
/// Runs on the root isolate (required for [PortablePty] native assets). Reads
/// are scheduled on the UI scheduler with a short delay after spawn so setup
/// commands and keyboard input are not starved by a blocking [readSync].
class GhosttyWindowsPtyBridge {
  GhosttyWindowsPtyBridge({
    required this.controller,
    this.initialRows = 32,
    this.initialCols = 120,
  })  : _rows = initialRows,
        _cols = initialCols;

  final GhosttyTerminalController controller;
  final int initialRows;
  final int initialCols;

  static const _pollInterval = Duration(milliseconds: 32);
  static const _flushDelay = Duration(milliseconds: 32);
  static const _readChunkSize = 4096;
  static const _maxReadsPerTick = 4;
  static const _readStartDelay = Duration(milliseconds: 280);

  PortablePty? _pty;
  Timer? _readTimer;
  final BytesBuilder _pendingOutput = BytesBuilder();
  Timer? _flushTimer;
  late int _rows;
  late int _cols;
  bool _closed = false;
  bool _readsStarted = false;

  Future<void> start(GhosttyTerminalShellLaunch launch) async {
    controller.attachExternalTransport(
      writeBytes: _writeBytes,
      onResize: _onResize,
      launch: launch,
    );

    final pty = PortablePty.open(rows: _rows, cols: _cols);
    _pty = pty;

    pty.spawn(
      launch.shell,
      args: launch.arguments,
      environment: launch.environment,
    );

    final setup = launch.setupCommand;
    if (setup != null && setup.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!_closed) {
        _writeBytes(utf8.encode(setup));
      }
    }

    if (!_closed) {
      _scheduleReadLoopStart();
    }
  }

  void _scheduleReadLoopStart() {
    Future<void>.delayed(_readStartDelay, () {
      if (_closed || _readsStarted) return;
      _readsStarted = true;
      _readTimer = Timer.periodic(_pollInterval, (_) => _schedulePollRead());
      _schedulePollRead();
    });
  }

  void _schedulePollRead() {
    if (_closed) return;
    SchedulerBinding.instance.scheduleTask<void>(
      _pollRead,
      Priority.idle,
    );
  }

  void _pollRead() {
    final pty = _pty;
    if (pty == null || _closed) return;

    final exited = pty.tryWait();
    if (exited != null) {
      _flushNow();
      _handleExit(exited);
      return;
    }

    var reads = 0;
    while (reads < _maxReadsPerTick) {
      try {
        final bytes = pty.readSync(_readChunkSize);
        if (bytes.isEmpty) {
          break;
        }
        _pendingOutput.add(bytes);
        reads++;
        if (bytes.length < _readChunkSize) {
          break;
        }
      } on StateError {
        break;
      } catch (_) {
        break;
      }
    }

    if (_pendingOutput.isNotEmpty) {
      _scheduleFlush();
    }

    final exitAfterRead = pty.tryWait();
    if (exitAfterRead != null) {
      _flushNow();
      _handleExit(exitAfterRead);
    }
  }

  void _onResize(int cols, int rows, int cellWidthPx, int cellHeightPx) {
    _cols = cols;
    _rows = rows;
    try {
      _pty?.resize(rows: rows, cols: cols);
    } catch (_) {}
  }

  void _scheduleFlush() {
    if (_flushTimer != null || _closed) return;
    _flushTimer = Timer(_flushDelay, _flushNow);
  }

  void _flushNow() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_closed || _pendingOutput.isEmpty) return;

    final chunk = _pendingOutput.toBytes();
    _pendingOutput.clear();
    controller.appendOutputBytes(chunk);
  }

  bool _writeBytes(List<int> bytes) {
    final pty = _pty;
    if (pty == null || _closed || bytes.isEmpty) return false;
    try {
      pty.writeBytes(Uint8List.fromList(bytes));
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

    _readTimer?.cancel();
    _readTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _flushNow();

    final pty = _pty;
    _pty = null;
    if (pty != null) {
      try {
        if (pty.tryWait() == null) {
          pty.kill();
        }
      } catch (_) {}
      try {
        pty.close();
      } catch (_) {}
    }

    controller.detachExternalTransport();
    controller.setSessionRunning(false);
  }
}
