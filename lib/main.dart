import 'package:flutter/material.dart';
import 'package:ghostty_vte_flutter/ghostty_vte_flutter.dart';

import 'screens/main_shell_screen.dart';
import 'services/config_store.dart';
import 'services/run_history_store.dart';
import 'theme/app_theme.dart';
import 'widgets/terminal_font_metrics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeGhosttyVteWeb();
  await TerminalFontMetrics.load();
  runApp(const GitHelperApp());
}

class GitHelperApp extends StatelessWidget {
  const GitHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Git Helper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: MainShellScreen(
        store: ConfigStore(),
        historyStore: RunHistoryStore(),
      ),
    );
  }
}
