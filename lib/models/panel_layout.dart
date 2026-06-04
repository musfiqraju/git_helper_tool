enum PanelLayout {
  stacked,
  sideBySide;

  String get label => switch (this) {
        PanelLayout.stacked => 'Grid top · Terminal bottom',
        PanelLayout.sideBySide => 'Grid left · Terminal right',
      };

  String get shortLabel => switch (this) {
        PanelLayout.stacked => 'Stacked',
        PanelLayout.sideBySide => 'Side by side',
      };

  static PanelLayout fromString(String? value) {
    return PanelLayout.values.firstWhere(
      (l) => l.name == value,
      orElse: () => PanelLayout.stacked,
    );
  }

  double defaultTerminalRatio() => switch (this) {
        PanelLayout.stacked => 0.32,
        PanelLayout.sideBySide => 0.5,
      };
}
