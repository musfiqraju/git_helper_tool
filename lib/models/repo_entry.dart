import 'dart:io';

import 'package:path/path.dart' as p;

enum RepoStatus {
  ok,
  missing,
  notGitRepo,
}

class RepoEntry {
  RepoEntry({
    required this.id,
    required this.path,
    required this.displayName,
    this.customCommand,
  });

  final String id;
  final String path;
  final String displayName;
  final String? customCommand;

  RepoStatus get status {
    final dir = Directory(path);
    if (!dir.existsSync()) return RepoStatus.missing;
    if (!Directory(p.join(path, '.git')).existsSync()) {
      return RepoStatus.notGitRepo;
    }
    return RepoStatus.ok;
  }

  bool get isRunnable => status == RepoStatus.ok;

  String commandFor(String defaultCommand) =>
      (customCommand?.trim().isNotEmpty ?? false)
          ? customCommand!.trim()
          : defaultCommand;

  RepoEntry copyWith({
    String? path,
    String? displayName,
    String? customCommand,
    bool clearCustomCommand = false,
  }) {
    return RepoEntry(
      id: id,
      path: path ?? this.path,
      displayName: displayName ?? this.displayName,
      customCommand:
          clearCustomCommand ? null : (customCommand ?? this.customCommand),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'displayName': displayName,
        'customCommand': customCommand,
      };

  factory RepoEntry.fromJson(Map<String, dynamic> json) {
    return RepoEntry(
      id: json['id'] as String,
      path: json['path'] as String,
      displayName: json['displayName'] as String,
      customCommand: json['customCommand'] as String?,
    );
  }

  static RepoEntry fromPath(String path, {String? id}) {
    final normalized = p.normalize(p.absolute(path));
    return RepoEntry(
      id: id ?? '',
      path: normalized,
      displayName: p.basename(normalized),
    );
  }
}
