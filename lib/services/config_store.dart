import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/app_config.dart';
import '../models/repo_entry.dart';

class ConfigStore {
  ConfigStore({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  AppConfig _config = AppConfig.empty();
  String? _configPath;

  AppConfig get config => _config;
  String? get configPath => _configPath;

  Future<void> load() async {
    _configPath = await _resolveConfigPath();
    final file = File(_configPath!);
    if (!await file.exists()) {
      _config = AppConfig.empty();
      await save();
      return;
    }
    try {
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      _config = AppConfig.fromJson(json);
    } catch (_) {
      _config = AppConfig.empty();
      await save();
    }
  }

  Future<void> save() async {
    _configPath ??= await _resolveConfigPath();
    final file = File(_configPath!);
    await file.parent.create(recursive: true);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(_config.toJson()));
  }

  Future<String> _resolveConfigPath() async {
    final dir = await getApplicationSupportDirectory();
    final configDir = Directory(p.join(dir.path, 'git_helper_tool'));
    return p.join(configDir.path, 'config.json');
  }

  Future<void> updateSettings({
    String? defaultCommand,
    RunMode? runMode,
    PanelLayout? panelLayout,
    double? terminalPanelRatio,
  }) async {
    _config = _config.copyWith(
      defaultCommand: defaultCommand,
      runMode: runMode,
      panelLayout: panelLayout,
      terminalPanelRatio: terminalPanelRatio,
    );
    await save();
  }

  Future<void> updateTerminalPanelRatio(double ratio) async {
    _config = _config.copyWith(
      terminalPanelRatio: ratio.clamp(0.12, 0.88),
    );
    await save();
  }

  Future<AddRepoResult> addRepo(String folderPath) async {
    final entry = RepoEntry.fromPath(folderPath, id: _uuid.v4());
    if (entry.status == RepoStatus.notGitRepo) {
      return AddRepoResult.notGitRepo;
    }
    final normalized = entry.path;
    final exists = _config.repos.any(
      (r) => _pathsEqual(r.path, normalized),
    );
    if (exists) return AddRepoResult.duplicate;

    _config = _config.copyWith(
      repos: [..._config.repos, entry],
    );
    await save();
    return AddRepoResult.added;
  }

  Future<void> removeRepo(String id) async {
    _config = _config.copyWith(
      repos: _config.repos.where((r) => r.id != id).toList(),
    );
    await save();
  }

  Future<void> relinkRepo(String id, String newPath) async {
    final entry = RepoEntry.fromPath(newPath, id: id);
    if (entry.status == RepoStatus.notGitRepo) {
      throw StateError('not_git_repo');
    }
    final normalized = entry.path;
    final duplicate = _config.repos.any(
      (r) => r.id != id && _pathsEqual(r.path, normalized),
    );
    if (duplicate) throw StateError('duplicate');

    _config = _config.copyWith(
      repos: _config.repos
          .map(
            (r) => r.id == id
                ? entry.copyWith(
                    customCommand: r.customCommand,
                  )
                : r,
          )
          .toList(),
    );
    await save();
  }

  Future<void> updateRepoCommand(String id, String? customCommand) async {
    _config = _config.copyWith(
      repos: _config.repos
          .map(
            (r) => r.id == id
                ? r.copyWith(
                    customCommand: customCommand,
                    clearCustomCommand: customCommand == null,
                  )
                : r,
          )
          .toList(),
    );
    await save();
  }
}

enum AddRepoResult {
  added,
  duplicate,
  notGitRepo,
}

bool _pathsEqual(String a, String b) {
  return p.equals(
    p.normalize(a).toLowerCase(),
    p.normalize(b).toLowerCase(),
  );
}
