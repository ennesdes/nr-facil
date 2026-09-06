import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_filter_chip.dart';

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

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppFilterChip(
              label: 'Sistema',
              icon: Icons.brightness_auto_outlined,
              selected: selected == ThemeMode.system,
              onTap: () => controller.setThemeMode(ThemeMode.system),
            ),
            AppFilterChip(
              label: 'Claro',
              icon: Icons.light_mode_outlined,
              selected: selected == ThemeMode.light,
              onTap: () => controller.setThemeMode(ThemeMode.light),
            ),
            AppFilterChip(
              label: 'Escuro',
              icon: Icons.dark_mode_outlined,
              selected: selected == ThemeMode.dark,
              onTap: () => controller.setThemeMode(ThemeMode.dark),
            ),
          ],
        );
      },
    );
  }
}
