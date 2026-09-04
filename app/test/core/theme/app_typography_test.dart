import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_colors.dart';
import 'package:nrfacil/core/theme/app_typography.dart';

void main() {
  test('textTheme light usa onSurface do ColorScheme', () {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onSurface: AppColors.onSurface,
    );
    final theme = AppTypography.textTheme(scheme);

    expect(theme.bodyLarge?.color, AppColors.onSurface);
    expect(theme.bodySmall?.color, AppColors.onSurface);
    expect(theme.titleMedium?.color, AppColors.onSurface);
  });

  test('textTheme dark usa onSurfaceDark do ColorScheme', () {
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryDark,
      onSurface: AppColors.onSurfaceDark,
    );
    final theme = AppTypography.textTheme(scheme);

    expect(theme.bodyLarge?.color, AppColors.onSurfaceDark);
    expect(theme.bodySmall?.color, AppColors.onSurfaceDark);
    expect(theme.titleMedium?.color, AppColors.onSurfaceDark);
  });
}
