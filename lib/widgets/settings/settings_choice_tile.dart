import 'package:flutter/material.dart';

import '../../theme/settings_colors.dart';

class SettingsChoiceTile extends StatelessWidget {
  const SettingsChoiceTile({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 480;
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
    final iconColor = selected
        ? SettingsColors.accentBlue(context)
        : SettingsColors.textSecondary(context);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isWide ? 16 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: selected ? 2 : 1,
              color: borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? SettingsColors.accentBlue(context).withValues(alpha: 0.12)
                      : SettingsColors.textPrimary(context).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: descColor,
                      ),
                    ),
                  ],
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
        ),
      ),
    );
  }
}
