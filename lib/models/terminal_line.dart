enum TerminalLineKind {
  info,
  command,
  stdout,
  stderr,
  success,
  error,
  skipped,
}

class TerminalLine {
  TerminalLine({
    required this.text,
    required this.kind,
    this.repoName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String text;
  final TerminalLineKind kind;
  final String? repoName;
  final DateTime timestamp;
}
