import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_colors.dart';
import 'package:nrfacil/core/theme/app_system_ui.dart';

void main() {
  group('AppSystemUi.overlayFor', () {
    test('tema claro usa fundo surface e ícones escuros', () {
      final overlay = AppSystemUi.overlayFor(
        brightness: Brightness.light,
        surface: AppColors.surface,
      );

      expect(overlay.systemNavigationBarColor, AppColors.surface);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.dark);
      expect(overlay.statusBarIconBrightness, Brightness.dark);
      expect(overlay.systemNavigationBarContrastEnforced, isTrue);
    });

    test('tema escuro usa fundo surface e ícones claros', () {
      final overlay = AppSystemUi.overlayFor(
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
      );

      expect(overlay.systemNavigationBarColor, AppColors.surfaceDark);
      expect(overlay.systemNavigationBarIconBrightness, Brightness.light);
      expect(overlay.statusBarIconBrightness, Brightness.light);
    });
  });
}
