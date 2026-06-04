import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';
import 'package:portable_pty/portable_pty_bindings_generated.dart' as pty;

/// Windows ConPTY transport for [GhosttyTerminalController].
///
/// On Windows the native `portable_pty` read is **blocking** and ConPTY exposes
/// no pollable file descriptor (`masterFd` is `-1`), so the non-blocking
/// `fcntl` trick the package relies on for Linux/macOS cannot apply — which is
/// exactly why the package excludes Windows from its built-in PTY backend.
///
/// Calling that blocking read on the UI isolate froze the whole app whenever the
/// shell was idle (sitting at a prompt). The terminal looked dead: the
/// prompt/working directory never painted and keystrokes — Ctrl+C included —
/// never reached the child.
///
/// This bridge owns the raw PTY handle and runs the blocking read loop on a
/// dedicated [Isolate]. Output is streamed back to the UI isolate over a port;
/// input, resize, exit-detection, and shutdown run on the UI isolate against the
/// same handle. The native struct guards reads and writes with *separate*
/// mutexes, so reading on the worker isolate while writing on the UI isolate is
/// safe.
///
/// Lifecycle note: ConPTY keeps the output open while we hold the master, so the
/// worker's read only unblocks when [pty.portable_pty_close] drops the master.
/// Killing the child does **not** unblock it. Shutdown therefore closes the
/// handle directly; the worker then returns from its in-flight read (which makes
/// it break its loop) and exits without touching the freed handle again.
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

  static const _readChunkSize = 8192;
  // Coalesce reader output into at most one VT ingest per frame to avoid
  // rebuilding the terminal on every 8 KB chunk during high-output commands.
  static const _flushInterval = Duration(milliseconds: 16);
  static const _setupDelay = Duration(milliseconds: 120);
  // Poll for natural shell exit (e.g. the user typed `exit`). ConPTY will not
  // EOF the read on its own, so we detect it here and then close to unblock.
  static const _exitPollInterval = Duration(seconds: 1);

  ffi.Pointer<pty.PortablePty> _handle = ffi.nullptr;
  Isolate? _readerIsolate;
  ReceivePort? _fromReader;
  StreamSubscription<dynamic>? _fromReaderSub;

  final BytesBuilder _pendingOutput = BytesBuilder(copy: false);
  Timer? _flushTimer;
  Timer? _exitPollTimer;

  int _rows;
  int _cols;
  bool _closed = false;
  bool _handleClosed = false;
  bool _exitReported = false;

  Future<void> start(GhosttyTerminalShellLaunch launch) async {
    controller.attachExternalTransport(
      writeBytes: _writeBytes,
      onResize: _onResize,
      launch: launch,
    );

    final handle = _openAndSpawn(launch);
    _handle = handle;

    // Drain output before sending any setup input so the very first prompt —
    // and the project-directory prompt after `Set-Location` — is captured.
    await _startReader(handle.address);

    final setup = launch.setupCommand;
    if (setup != null && setup.isNotEmpty) {
      // Let PowerShell emit its initial prompt before we send `cd`, so the
      // setup command lands cleanly instead of racing shell start-up.
      await Future<void>.delayed(_setupDelay);
      if (!_closed) {
        _writeBytes(utf8.encode(setup));
      }
    }

    if (!_closed) {
      _exitPollTimer = Timer.periodic(_exitPollInterval, (_) => _pollExit());
    }
  }

  // --- Native PTY lifecycle (UI isolate) -----------------------------------

  ffi.Pointer<pty.PortablePty> _openAndSpawn(
    GhosttyTerminalShellLaunch launch,
  ) {
    final out = calloc<ffi.Pointer<pty.PortablePty>>();
    try {
      final opened = pty.portable_pty_open(_rows, _cols, out);
      if (opened != pty.PortablePtyResult.Ok) {
        throw StateError('portable_pty_open failed ($opened)');
      }
      final handle = out.value;
      if (handle == ffi.nullptr) {
        throw StateError('portable_pty_open returned a null handle');
      }
      try {
        _spawn(handle, launch);
      } catch (_) {
        // Don't leak the opened PTY if spawning the shell failed.
        try {
          pty.portable_pty_close(handle);
        } catch (_) {}
        rethrow;
      }
      return handle;
    } finally {
      calloc.free(out);
    }
  }

  void _spawn(
    ffi.Pointer<pty.PortablePty> handle,
    GhosttyTerminalShellLaunch launch,
  ) {
    final cmdPtr = launch.shell.toNativeUtf8().cast<ffi.Char>();
    ffi.Pointer<ffi.Pointer<ffi.Char>> argvPtr = ffi.nullptr;
    ffi.Pointer<ffi.Pointer<ffi.Char>> envpPtr = ffi.nullptr;
    try {
      final allArgs = <String>[launch.shell, ...launch.arguments];
      argvPtr = calloc<ffi.Pointer<ffi.Char>>(allArgs.length + 1);
      for (var i = 0; i < allArgs.length; i++) {
        argvPtr[i] = allArgs[i].toNativeUtf8().cast<ffi.Char>();
      }
      argvPtr[allArgs.length] = ffi.nullptr;

      final environment = launch.environment;
      if (environment != null) {
        final entries =
            environment.entries.map((e) => '${e.key}=${e.value}').toList();
        envpPtr = calloc<ffi.Pointer<ffi.Char>>(entries.length + 1);
        for (var i = 0; i < entries.length; i++) {
          envpPtr[i] = entries[i].toNativeUtf8().cast<ffi.Char>();
        }
        envpPtr[entries.length] = ffi.nullptr;
      }

      final spawned =
          pty.portable_pty_spawn(handle, cmdPtr, argvPtr, envpPtr);
      if (spawned != pty.PortablePtyResult.Ok) {
        throw StateError('portable_pty_spawn failed ($spawned)');
      }
    } finally {
      calloc.free(cmdPtr);
      if (argvPtr != ffi.nullptr) {
        for (var i = 0; argvPtr[i] != ffi.nullptr; i++) {
          calloc.free(argvPtr[i]);
        }
        calloc.free(argvPtr);
      }
      if (envpPtr != ffi.nullptr) {
        for (var i = 0; envpPtr[i] != ffi.nullptr; i++) {
          calloc.free(envpPtr[i]);
        }
        calloc.free(envpPtr);
      }
    }
  }

  bool _writeBytes(List<int> bytes) {
    final handle = _handle;
    if (_closed || _handleClosed || handle == ffi.nullptr || bytes.isEmpty) {
      return false;
    }
    final buf = calloc<ffi.Uint8>(bytes.length);
    try {
      buf.asTypedList(bytes.length).setAll(0, bytes);
      final n = pty.portable_pty_write(handle, buf, bytes.length);
      return n >= 0;
    } catch (_) {
      return false;
    } finally {
      calloc.free(buf);
    }
  }

  void _onResize(int cols, int rows, int cellWidthPx, int cellHeightPx) {
    _cols = cols;
    _rows = rows;
    final handle = _handle;
    if (_closed || _handleClosed || handle == ffi.nullptr) return;
    try {
      pty.portable_pty_resize(handle, rows, cols);
    } catch (_) {}
  }

  /// Non-blocking check for the shell having exited on its own.
  void _pollExit() {
    final handle = _handle;
    if (_closed || _handleClosed || handle == ffi.nullptr) return;
    final status = calloc<ffi.Int>();
    try {
      if (pty.portable_pty_wait(handle, status) == pty.PortablePtyResult.Ok) {
        _reportExit(status.value);
        // Drop the master so the worker's blocking read returns, then tear down.
        _closeHandle();
      }
    } catch (_) {
    } finally {
      calloc.free(status);
    }
  }

  // --- Reader isolate plumbing (UI isolate side) ---------------------------

  Future<void> _startReader(int handleAddress) async {
    final fromReader = ReceivePort();
    _fromReader = fromReader;
    _fromReaderSub = fromReader.listen(_onReaderMessage);

    _readerIsolate = await Isolate.spawn<_ReaderConfig>(
      _readerMain,
      _ReaderConfig(handleAddress, fromReader.sendPort, _readChunkSize),
      debugName: 'ghostty-pty-reader',
    );
  }

  void _onReaderMessage(dynamic message) {
    if (message is Uint8List) {
      _enqueueOutput(message);
    } else if (message is String && !_closed) {
      // Surfaced reader-side failure (e.g. native read error).
      controller.appendOutputBytes(utf8.encode('\r\n[$message]\r\n'));
    }
  }

  void _enqueueOutput(Uint8List bytes) {
    if (_closed || bytes.isEmpty) return;
    _pendingOutput.add(bytes);
    _flushTimer ??= Timer(_flushInterval, _flushOutput);
  }

  void _flushOutput() {
    _flushTimer = null;
    if (_closed || _pendingOutput.isEmpty) return;
    controller.appendOutputBytes(_pendingOutput.takeBytes());
  }

  void _reportExit(int exitCode) {
    if (_exitReported || _closed) return;
    _exitReported = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingOutput.isNotEmpty) {
      controller.appendOutputBytes(_pendingOutput.takeBytes());
    }
    controller.appendOutputBytes(
      utf8.encode('\r\n[process exited: $exitCode]\r\n'),
    );
    controller.setSessionRunning(false);
  }

  void dispose() {
    if (_closed) return;
    _closed = true;

    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingOutput.clear();

    controller.detachExternalTransport();
    controller.setSessionRunning(false);

    _closeHandle();
  }

  /// Closes the PTY (which unblocks and ends the reader isolate) and releases
  /// all UI-side resources. Safe to call more than once.
  void _closeHandle() {
    if (_handleClosed) return;
    _handleClosed = true;

    _exitPollTimer?.cancel();
    _exitPollTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;

    final handle = _handle;
    _handle = ffi.nullptr;
    if (handle != ffi.nullptr) {
      // Dropping the master unblocks the worker's in-flight read; because the
      // read then returns <= 0 the worker breaks its loop and never touches the
      // freed handle again.
      try {
        pty.portable_pty_close(handle);
      } catch (_) {}
    }

    _fromReaderSub?.cancel();
    _fromReaderSub = null;
    _fromReader?.close();
    _fromReader = null;
    _readerIsolate?.kill(priority: Isolate.immediate);
    _readerIsolate = null;
  }
}

/// Immutable payload handed to the reader isolate.
class _ReaderConfig {
  const _ReaderConfig(this.handleAddress, this.sendPort, this.chunkSize);

  final int handleAddress;
  final SendPort sendPort;
  final int chunkSize;
}

/// Entry point for the reader isolate.
///
/// Performs blocking [pty.portable_pty_read] calls against the shared handle and
/// streams each chunk back to the UI isolate. A read result of `<= 0` only
/// happens once the UI isolate has closed the PTY, so the loop simply breaks and
/// the isolate exits without touching the (now-freed) handle again.
void _readerMain(_ReaderConfig config) {
  final handle =
      ffi.Pointer<pty.PortablePty>.fromAddress(config.handleAddress);
  final buf = calloc<ffi.Uint8>(config.chunkSize);
  try {
    while (true) {
      final n = pty.portable_pty_read(handle, buf, config.chunkSize);
      if (n <= 0) {
        break;
      }
      config.sendPort.send(Uint8List.fromList(buf.asTypedList(n)));
    }
  } catch (e) {
    // Best-effort diagnostic; the handle may already be closed by the UI side.
    try {
      config.sendPort.send('terminal reader stopped: $e');
    } catch (_) {}
  } finally {
    calloc.free(buf);
  }
}
