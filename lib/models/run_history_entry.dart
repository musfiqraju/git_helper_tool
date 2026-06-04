import 'command_result.dart';

class RunHistoryEntry {
  RunHistoryEntry({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.defaultCommand,
    required this.runMode,
    required this.results,
  });

  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String defaultCommand;
  final String runMode;
  final List<CommandResult> results;

  int get successCount => results.where((r) => r.success).length;
  int get failCount => results.length - successCount;
  bool get allSucceeded => failCount == 0 && results.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'defaultCommand': defaultCommand,
        'runMode': runMode,
        'results': results.map(_resultToJson).toList(),
      };

  factory RunHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RunHistoryEntry(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: DateTime.parse(json['finishedAt'] as String),
      defaultCommand: json['defaultCommand'] as String,
      runMode: json['runMode'] as String,
      results: (json['results'] as List<dynamic>)
          .map((e) => _resultFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static Map<String, dynamic> _resultToJson(CommandResult r) => {
        'repoId': r.repoId,
        'repoName': r.repoName,
        'command': r.command,
        'exitCode': r.exitCode,
        'stdout': r.stdout,
        'stderr': r.stderr,
        'durationMs': r.durationMs,
        'skipped': r.skipped,
        'skipReason': r.skipReason,
      };

  static CommandResult _resultFromJson(Map<String, dynamic> json) {
    return CommandResult(
      repoId: json['repoId'] as String,
      repoName: json['repoName'] as String,
      command: json['command'] as String,
      exitCode: json['exitCode'] as int,
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      skipped: json['skipped'] as bool? ?? false,
      skipReason: json['skipReason'] as String?,
    );
  }
}
