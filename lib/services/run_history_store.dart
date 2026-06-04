import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/run_history_entry.dart';

class RunHistoryStore {
  RunHistoryStore({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final List<RunHistoryEntry> _entries = [];
  String? _historyPath;
  static const _maxEntries = 200;

  List<RunHistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    _historyPath = await _resolveHistoryPath();
    final file = File(_historyPath!);
    if (!await file.exists()) return;

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final list = json['runs'] as List<dynamic>? ?? [];
      _entries
        ..clear()
        ..addAll(
          list.map(
            (e) => RunHistoryEntry.fromJson(e as Map<String, dynamic>),
          ),
        );
      _entries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      _entries.clear();
    }
  }

  Future<void> addRun(RunHistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    await _save();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _save();
  }

  Future<void> _save() async {
    _historyPath ??= await _resolveHistoryPath();
    final file = File(_historyPath!);
    await file.parent.create(recursive: true);
    final data = {
      'runs': _entries.map((e) => e.toJson()).toList(),
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  Future<String> _resolveHistoryPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'git_helper_tool', 'history.json');
  }

  String newRunId() => _uuid.v4();
}
