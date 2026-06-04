class CommandResult {
  CommandResult({
    required this.repoId,
    required this.repoName,
    required this.command,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.durationMs,
    this.skipped = false,
    this.skipReason,
  });

  final String repoId;
  final String repoName;
  final String command;
  final int exitCode;
  final String stdout;
  final String stderr;
  final int durationMs;
  final bool skipped;
  final String? skipReason;

  bool get success => !skipped && exitCode == 0;
}
