# Git Helper Tool

Cross-platform **Flutter desktop** app to manage multiple git repositories in different folders and run a command (default: `git pull origin main`) across all of them with one click.

Works on **Windows**, **macOS**, and **Linux**.

## Features

- **Enlist folders** via native directory picker (validates `.git` exists)
- **Persistent list** saved to a local JSON config file until you remove or re-link a repo
- **Run all** executes the default command in every valid repo
- **Global default command** editable in Settings
- **Per-repo command override** (optional) from each repo’s menu
- **Parallel or sequential** execution mode in Settings
- **Responsive grid** for enlisted repos (1–6 columns based on pane width)
- **Panel layout** in Settings: grid on top + terminal below, or grid left + terminal right (50/50 default)
- **Resizable divider** between grid and terminal; split size is saved to config
- **Live terminal** at the bottom with real-time stdout/stderr as commands run
- **Task-complete notification** (banner + snackbar with **Report** action)
- **Run history report** — all past runs with success/failed filter and full error output
- **Status chips** for missing paths or non-git folders, with **Re-link** support

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with desktop support
- **Git** installed and available on your system `PATH`

### Enable desktop (once)

```bash
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

## Run from source

```bash
cd git_helper_tool
flutter pub get
flutter run -d windows   # or macos / linux
```

## Build release

```bash
flutter build windows
flutter build macos
flutter build linux
```

Binaries are under `build/` for each platform.

## Tabs

| Tab | Purpose |
|-----|---------|
| **Batch runner** | Grid of repos, run one command across all (original workflow) |
| **Terminals** | Project list (names only) on the left; double-click to open an interactive terminal per project on the right |

In **Terminals**, double-click a project to open a **full embedded terminal** ([Ghostty VT](https://pub.dev/packages/ghostty_vte_flutter)) in that folder — PowerShell on Windows, bash on macOS/Linux. Click the terminal pane and type as in a normal terminal (arrow keys, PSReadLine, Ctrl+C, paste, selection). Use tabs on the right to switch between open sessions.

On the first `flutter run` / `flutter build`, native PTY libraries are downloaded automatically by the package build hooks.

## Usage

1. Click **Add folder** and select the root of a git repository.
2. Repeat for all projects you want to manage (any location on disk).
3. Optionally open **Settings** to change the default command or run mode.
4. Click **Run all** — watch output stream in the **terminal** panel.
5. When the task finishes, use the notification or **Report** in the app bar to view full history (success/failed, stderr, stdout).

### Per-repo command

Open the **⋮** menu on a repo → **Edit command**. Leave empty to use the global default, or set a custom line (e.g. `git pull origin develop`). Use **Use default** to clear an override.

### Moved folder

If a path no longer exists, the repo shows **Missing**. Use **Re-link folder** to point it to the new location (keeps overrides and id).

## Config file location

Settings shows the full path. Typical locations:

| OS      | Path |
|---------|------|
| Windows | `%APPDATA%\git_helper_tool\config.json` (under app support via `path_provider`) |
| macOS   | `~/Library/Application Support/git_helper_tool/config.json` |
| Linux   | `~/.local/share/git_helper_tool/config.json` (may vary slightly) |

Example `config.json`:

```json
{
  "defaultCommand": "git pull origin main",
  "runMode": "parallel",
  "repos": [
    {
      "id": "uuid-here",
      "path": "C:/Users/you/projects/my-app",
      "displayName": "my-app",
      "customCommand": null
    }
  ]
}
```

## Command format

Commands are split on whitespace (v1). Example: `git pull origin main` runs as `git` with arguments `pull`, `origin`, `main` in each repo’s directory. On Windows, commands run in a shell for better compatibility.

Complex quoted arguments are not supported in v1.

## History file

Run reports are saved to `history.json` next to `config.json` (same app data folder). Up to 200 runs are kept.

## Project structure

```
lib/
  main.dart
  models/          # AppConfig, RepoEntry, CommandResult, RunHistoryEntry, TerminalLine
  services/        # ConfigStore, GitCommandRunner, RunHistoryStore
  screens/         # HomeScreen, SettingsScreen, ReportScreen
  widgets/         # RepoGridCard, LiveTerminalPanel
  utils/           # gridColumnsForWidth
```

## License

Private / local use — see repository owner for licensing if applicable.
