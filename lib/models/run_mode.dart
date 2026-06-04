enum RunMode {
  parallel,
  sequential;

  String get label => switch (this) {
        RunMode.parallel => 'Parallel',
        RunMode.sequential => 'Sequential',
      };

  static RunMode fromString(String value) {
    return RunMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => RunMode.parallel,
    );
  }
}
