import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';

extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppSemanticColors.light;

  Color get searchHighlightColor => semanticColors.searchHighlight;

  Color get onSearchHighlightColor => semanticColors.onSearchHighlight;

  Color get mutedTextColor => semanticColors.muted;

  /// Fundo do corpo do leitor — mais suave que o scaffold para leitura prolongada.
  Color get readerSurfaceColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppColors.readerSurfaceDark
        : AppColors.readerSurface;
  }
}
