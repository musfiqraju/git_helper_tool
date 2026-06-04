import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_config.dart';
import '../services/config_store.dart';
import '../theme/settings_colors.dart';
import '../widgets/settings/layout_preview_tile.dart';
import '../widgets/settings/settings_choice_tile.dart';
import '../widgets/settings/settings_layout.dart';
import '../widgets/settings/settings_section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.store,
    required this.onSaved,
  });

  final ConfigStore store;
  final VoidCallback onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _commandController;
  late RunMode _runMode;
  late PanelLayout _panelLayout;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config = widget.store.config;
    _commandController = TextEditingController(text: config.defaultCommand);
    _runMode = config.runMode;
    _panelLayout = config.panelLayout;
  }

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) {
      _showSnack('Default command cannot be empty');
      return;
    }
    setState(() => _saving = true);
    final layoutChanged = _panelLayout != widget.store.config.panelLayout;
    await widget.store.updateSettings(
      defaultCommand: command,
      runMode: _runMode,
      panelLayout: _panelLayout,
      terminalPanelRatio: layoutChanged
          ? _panelLayout.defaultTerminalRatio()
          : null,
    );
    setState(() => _saving = false);
    widget.onSaved();
    if (mounted) {
      _showSnack('Settings saved');
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configPath = widget.store.configPath ?? 'Loading...';
    final sectionGap = SettingsLayout.sectionGap(context);
    final columns = SettingsLayout.optionColumns(context);
    final padding = SettingsLayout.pagePadding(context);

    final bg = SettingsColors.pageBackground(context);
    final textPrimary = SettingsColors.textPrimary(context);
    final textSecondary = SettingsColors.textSecondary(context);
    final accentBlue = SettingsColors.accentBlue(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SettingsLayout.maxContentWidth,
                  ),
                  child: ListView(
                    padding: padding,
                    children: _buildSections(
                      context,
                      configPath: configPath,
                      sectionGap: sectionGap,
                      columns: columns,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                12,
                padding.right,
                padding.bottom > 0 ? padding.bottom : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SettingsLayout.maxContentWidth,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accentBlue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving…' : 'Save settings'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context, {
    required String configPath,
    required double sectionGap,
    required int columns,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return [
      Text(
        'Preferences',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Customize commands, execution, and workspace layout.',
        style: TextStyle(fontSize: 12, height: 1.4, color: textSecondary),
      ),
      SizedBox(height: sectionGap + 4),
      SettingsSectionCard(
        title: 'Default command',
        subtitle: 'Runs in every repo unless a per-repo override is set.',
        icon: Icons.terminal_outlined,
        accentColor: SettingsColors.accentTeal(context),
        child: TextField(
          controller: _commandController,
          style: TextStyle(
            fontFamily: 'Consolas',
            fontSize: 14,
            color: textPrimary,
          ),
          cursorColor: SettingsColors.accentBlue(context),
          decoration: InputDecoration(
            filled: true,
            fillColor: SettingsColors.inputFill(context),
            hintText: AppConfig.defaultCommandValue,
            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.8)),
            helperText: 'Example: git pull origin main',
            helperStyle: TextStyle(color: textSecondary, fontSize: 12),
            prefixIcon: Icon(Icons.code, size: 22, color: textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: SettingsColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: SettingsColors.accentBlue(context),
                width: 2,
              ),
            ),
          ),
          maxLines: 2,
          minLines: 1,
        ),
      ),
      SizedBox(height: sectionGap),
      SettingsSectionCard(
        title: 'Execution',
        subtitle: 'How commands run across enlisted repositories.',
        icon: Icons.play_circle_outline,
        child: _buildRunModeSection(context, columns),
      ),
      SizedBox(height: sectionGap),
      SettingsSectionCard(
        title: 'Workspace layout',
        subtitle:
            'Arrange the repo grid and terminal. Resize with the divider on the home screen.',
        icon: Icons.dashboard_customize_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutPreviewPicker(
              selected: _panelLayout,
              onSelected: (l) => setState(() => _panelLayout = l),
            ),
            const SizedBox(height: 10),
            Text(
              'Changing layout resets the panel split to a balanced default.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: sectionGap),
      SettingsSectionCard(
        title: 'Storage',
        subtitle: 'Local configuration file on this device.',
        icon: Icons.folder_outlined,
        child: _ConfigPathBlock(path: configPath),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildRunModeSection(BuildContext context, int columns) {
    final gap = SettingsLayout.innerGap(context);
    final parallel = SettingsChoiceTile(
      title: RunMode.parallel.label,
      description:
          'All valid repos run at the same time. Fastest for many projects.',
      icon: Icons.sync,
      selected: _runMode == RunMode.parallel,
      onTap: () => setState(() => _runMode = RunMode.parallel),
    );
    final sequential = SettingsChoiceTile(
      title: RunMode.sequential.label,
      description:
          'One repo at a time. Easier to follow live terminal output.',
      icon: Icons.linear_scale,
      selected: _runMode == RunMode.sequential,
      onTap: () => setState(() => _runMode = RunMode.sequential),
    );

    if (columns == 1) {
      return Column(
        children: [
          parallel,
          SizedBox(height: gap),
          sequential,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: parallel),
          SizedBox(width: gap),
          Expanded(child: sequential),
        ],
      ),
    );
  }
}

class _ConfigPathBlock extends StatelessWidget {
  const _ConfigPathBlock({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SettingsColors.inputFill(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SettingsColors.border(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              path,
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 11,
                height: 1.45,
                color: SettingsColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copy path',
            icon: Icon(
              Icons.copy_outlined,
              size: 20,
              color: SettingsColors.textSecondary(context),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Path copied',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
