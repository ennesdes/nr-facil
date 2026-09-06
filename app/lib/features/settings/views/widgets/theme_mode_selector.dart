import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';

/// Seletor de tema Sistema / Claro / Escuro.
class ThemeModeSelector extends StatelessWidget {
  final ThemeController controller;

  const ThemeModeSelector({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final selected = controller.themeMode.value;

        return Row(
          children: [
            Expanded(
              child: _ThemeOption(
                icon: Icons.brightness_auto_outlined,
                label: 'Sistema',
                selected: selected == ThemeMode.system,
                onTap: () => controller.setThemeMode(ThemeMode.system),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ThemeOption(
                icon: Icons.light_mode_outlined,
                label: 'Claro',
                selected: selected == ThemeMode.light,
                onTap: () => controller.setThemeMode(ThemeMode.light),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ThemeOption(
                icon: Icons.dark_mode_outlined,
                label: 'Escuro',
                selected: selected == ThemeMode.dark,
                onTap: () => controller.setThemeMode(ThemeMode.dark),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final background = selected ? colorScheme.primary : Colors.transparent;
    final foreground =
        selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outline.withValues(alpha: 0.55);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: foreground),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
