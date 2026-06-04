import 'panel_layout.dart';
import 'repo_entry.dart';
import 'run_mode.dart';

export 'panel_layout.dart';
export 'run_mode.dart';

class AppConfig {
  AppConfig({
    required this.defaultCommand,
    required this.runMode,
    required this.panelLayout,
    required this.terminalPanelRatio,
    required this.repos,
  });

  static const defaultCommandValue = 'git pull origin main';

  final String defaultCommand;
  final RunMode runMode;
  final PanelLayout panelLayout;
  final double terminalPanelRatio;
  final List<RepoEntry> repos;

  factory AppConfig.empty() {
    const layout = PanelLayout.stacked;
    return AppConfig(
      defaultCommand: defaultCommandValue,
      runMode: RunMode.parallel,
      panelLayout: layout,
      terminalPanelRatio: layout.defaultTerminalRatio(),
      repos: [],
    );
  }

  int get runnableCount => repos.where((r) => r.isRunnable).length;

  AppConfig copyWith({
    String? defaultCommand,
    RunMode? runMode,
    PanelLayout? panelLayout,
    double? terminalPanelRatio,
    List<RepoEntry>? repos,
  }) {
    return AppConfig(
      defaultCommand: defaultCommand ?? this.defaultCommand,
      runMode: runMode ?? this.runMode,
      panelLayout: panelLayout ?? this.panelLayout,
      terminalPanelRatio: terminalPanelRatio ?? this.terminalPanelRatio,
      repos: repos ?? this.repos,
    );
  }

  Map<String, dynamic> toJson() => {
        'defaultCommand': defaultCommand,
        'runMode': runMode.name,
        'panelLayout': panelLayout.name,
        'terminalPanelRatio': terminalPanelRatio,
        'repos': repos.map((r) => r.toJson()).toList(),
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final layout = PanelLayout.fromString(json['panelLayout'] as String?);
    return AppConfig(
      defaultCommand: json['defaultCommand'] as String? ?? defaultCommandValue,
      runMode: RunMode.fromString(json['runMode'] as String? ?? 'parallel'),
      panelLayout: layout,
      terminalPanelRatio:
          (json['terminalPanelRatio'] as num?)?.toDouble() ??
              layout.defaultTerminalRatio(),
      repos: (json['repos'] as List<dynamic>? ?? [])
          .map((e) => RepoEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
