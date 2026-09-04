import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppSemanticColors.light;

  Color get searchHighlightColor =>
      semanticColors.warningContainer.withValues(alpha: 0.6);
}
