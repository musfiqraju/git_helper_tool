import 'package:flutter/material.dart';

import '../../models/panel_layout.dart';
import '../../theme/settings_colors.dart';

/// Layout picker with wireframe previews (responsive row).
class LayoutPreviewPicker extends StatelessWidget {
  const LayoutPreviewPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PanelLayout selected;
  final ValueChanged<PanelLayout> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gap = width >= 600 ? 14.0 : 10.0;
    final stackVertically = width < 520;

    final stacked = SettingsChoiceTileWithPreview(
      title: PanelLayout.stacked.shortLabel,
      description: 'Grid above terminal',
      icon: Icons.view_agenda_outlined,
      selected: selected == PanelLayout.stacked,
      onTap: () => onSelected(PanelLayout.stacked),
      preview: _LayoutPreview(layout: PanelLayout.stacked),
    );

    final sideBySide = SettingsChoiceTileWithPreview(
      title: PanelLayout.sideBySide.shortLabel,
      description: 'Grid left, terminal right',
      icon: Icons.view_sidebar_outlined,
      selected: selected == PanelLayout.sideBySide,
      onTap: () => onSelected(PanelLayout.sideBySide),
      preview: _LayoutPreview(layout: PanelLayout.sideBySide),
    );

    if (stackVertically) {
      return Column(
        children: [
          stacked,
          SizedBox(height: gap),
          sideBySide,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: stacked),
          SizedBox(width: gap),
          Expanded(child: sideBySide),
        ],
      ),
    );
  }
}

class SettingsChoiceTileWithPreview extends StatelessWidget {
  const SettingsChoiceTileWithPreview({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? SettingsColors.selectedTileBg(context)
        : SettingsColors.unselectedTileBg(context);
    final titleColor = selected
        ? SettingsColors.selectedTileText(context)
        : SettingsColors.textPrimary(context);
    final descColor = SettingsColors.textSecondary(context);
    final borderColor = selected
        ? SettingsColors.accentBlue(context)
        : SettingsColors.border(context);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width >= 600 ? 16 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: selected ? 2 : 1,
              color: borderColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 72, child: preview),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? SettingsColors.accentBlue(context)
                        : SettingsColors.textSecondary(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? SettingsColors.accentBlue(context)
                        : SettingsColors.textSecondary(context),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: descColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutPreview extends StatelessWidget {
  const _LayoutPreview({required this.layout});

  final PanelLayout layout;

  @override
  Widget build(BuildContext context) {
    final gridColor = SettingsColors.accentBlue(context).withValues(alpha: 0.25);
    final grid = Container(
      decoration: BoxDecoration(
        color: gridColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    final terminal = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SettingsColors.border(context)),
      ),
      child: Center(
        child: Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );

    if (layout == PanelLayout.stacked) {
      return Column(
        children: [
          Expanded(flex: 3, child: grid),
          const SizedBox(height: 4),
          Expanded(flex: 2, child: terminal),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 3, child: grid),
        const SizedBox(width: 4),
        Expanded(flex: 2, child: terminal),
      ],
    );
  }
}
