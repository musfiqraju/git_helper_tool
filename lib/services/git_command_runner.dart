import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/app_config.dart';
import '../models/command_result.dart';
import '../models/repo_entry.dart';
import '../models/terminal_line.dart';

typedef OnTerminalLine = void Function(TerminalLine line);

class GitCommandRunner {
  List<String> parseCommand(String commandLine) {
    final trimmed = commandLine.trim();
    if (trimmed.isEmpty) return [];
    return trimmed.split(RegExp(r'\s+'));
  }

  void _emit(
    OnTerminalLine? onLine,
    String text,
    TerminalLineKind kind, {
    String? repoName,
  }) {
    onLine?.call(
      TerminalLine(text: text, kind: kind, repoName: repoName),
    );
  }

  Future<CommandResult> runForRepo(
    RepoEntry repo,
    String commandLine, {
    OnTerminalLine? onLine,
  }) async {
    final command = repo.commandFor(commandLine);
    final prefix = repo.displayName;

    if (!repo.isRunnable) {
      final reason = switch (repo.status) {
        RepoStatus.missing => 'Path not found',
        RepoStatus.notGitRepo => 'Not a git repository',
        RepoStatus.ok => '',
      };
      _emit(
        onLine,
        '[$prefix] Skipped: $reason',
        TerminalLineKind.skipped,
        repoName: prefix,
      );
      return CommandResult(
        repoId: repo.id,
        repoName: repo.displayName,
        command: command,
        exitCode: -1,
        stdout: '',
        stderr: '',
        durationMs: 0,
        skipped: true,
        skipReason: reason,
      );
    }

    final args = parseCommand(command);
    if (args.isEmpty) {
      _emit(
        onLine,
        '[$prefix] Error: command is empty',
        TerminalLineKind.error,
        repoName: prefix,
      );
      return CommandResult(
        repoId: repo.id,
        repoName: repo.displayName,
        command: command,
        exitCode: -1,
        stdout: '',
        stderr: 'Command is empty',
        durationMs: 0,
      );
    }

    final executable = args.first;
    final execArgs = args.length > 1 ? args.sublist(1) : <String>[];

    _emit(
      onLine,
      '[$prefix] \$ $command',
      TerminalLineKind.command,
      repoName: prefix,
    );
    _emit(
      onLine,
      '[$prefix] Working directory: ${repo.path}',
      TerminalLineKind.info,
      repoName: prefix,
    );

    final stopwatch = Stopwatch()..start();
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();

    try {
      final process = await Process.start(
        executable,
        execArgs,
        workingDirectory: repo.path,
        runInShell: Platform.isWindows,
      );

      final stdoutDone = _streamLines(
        process.stdout,
        stdoutBuffer,
        onLine,
        prefix,
        TerminalLineKind.stdout,
      );
      final stderrDone = _streamLines(
        process.stderr,
        stderrBuffer,
        onLine,
        prefix,
        TerminalLineKind.stderr,
      );

      await Future.wait([stdoutDone, stderrDone]);
      final exitCode = await process.exitCode;
      stopwatch.stop();

      final result = CommandResult(
        repoId: repo.id,
        repoName: repo.displayName,
        command: command,
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );

      if (result.success) {
        _emit(
          onLine,
          '[$prefix] Finished successfully (${result.durationMs}ms)',
          TerminalLineKind.success,
          repoName: prefix,
        );
      } else {
        _emit(
          onLine,
          '[$prefix] Failed with exit code $exitCode (${result.durationMs}ms)',
          TerminalLineKind.error,
          repoName: prefix,
        );
      }
      return result;
    } catch (e) {
      stopwatch.stop();
      _emit(
        onLine,
        '[$prefix] Error: $e',
        TerminalLineKind.error,
        repoName: prefix,
      );
      return CommandResult(
        repoId: repo.id,
        repoName: repo.displayName,
        command: command,
        exitCode: -1,
        stdout: stdoutBuffer.toString(),
        stderr: e.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  Future<void> _streamLines(
    Stream<List<int>> stream,
    StringBuffer buffer,
    OnTerminalLine? onLine,
    String prefix,
    TerminalLineKind kind,
  ) async {
    final pending = StringBuffer();
    await for (final chunk in stream.transform(utf8.decoder)) {
      buffer.write(chunk);
      pending.write(chunk);
      _flushPendingLines(pending, onLine, prefix, kind);
    }
    final tail = pending.toString().trim();
    if (tail.isNotEmpty) {
      _emit(onLine, '[$prefix] $tail', kind, repoName: prefix);
    }
  }

  void _flushPendingLines(
    StringBuffer pending,
    OnTerminalLine? onLine,
    String prefix,
    TerminalLineKind kind,
  ) {
    var text = pending.toString();
    final lineBreak = RegExp(r'[\r\n]');
    int index;
    while ((index = text.indexOf(lineBreak)) != -1) {
      final line = text.substring(0, index).trimRight();
      text = text.substring(index + 1);
      if (text.startsWith('\n')) {
        text = text.substring(1);
      }
      if (line.isNotEmpty) {
        _emit(onLine, '[$prefix] $line', kind, repoName: prefix);
      }
    }
    pending
      ..clear()
      ..write(text);
  }

  Future<List<CommandResult>> runAll(
    AppConfig config, {
    OnTerminalLine? onLine,
  }) async {
    final repos = config.repos;
    final command = config.defaultCommand;

    _emit(
      onLine,
      '=== Starting run (${config.runMode.label}) · ${repos.length} repos ===',
      TerminalLineKind.info,
    );

    if (config.runMode == RunMode.parallel) {
      final futures = repos.map(
        (r) => runForRepo(r, command, onLine: onLine),
      );
      final results = await Future.wait(futures);
      _emitSummary(onLine, results);
      return results;
    }

    final results = <CommandResult>[];
    for (final repo in repos) {
      results.add(await runForRepo(repo, command, onLine: onLine));
    }
    _emitSummary(onLine, results);
    return results;
  }

  void _emitSummary(OnTerminalLine? onLine, List<CommandResult> results) {
    final ok = results.where((r) => r.success).length;
    final failed = results.length - ok;
    _emit(
      onLine,
      '=== Task complete: $ok succeeded, $failed failed ===',
      failed == 0 ? TerminalLineKind.success : TerminalLineKind.error,
    );
  }
}
