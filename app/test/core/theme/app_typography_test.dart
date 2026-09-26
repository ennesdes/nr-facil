import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(theme.bodyLarge?.fontFamily, AppTypography.fontFamily);
    expect(theme.bodyLarge?.fontWeight, FontWeight.w400);
    expect(theme.titleMedium?.fontWeight, FontWeight.w600);
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
    expect(theme.bodyLarge?.fontFamily, AppTypography.fontFamily);
    expect(theme.bodySmall?.color, AppColors.onSurfaceDark);
    expect(theme.titleMedium?.color, AppColors.onSurfaceDark);
  });

  test('fontes Inter empacotadas carregam do bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const files = [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
    ];
    for (final file in files) {
      final data = await rootBundle.load(file);
      expect(data.lengthInBytes, greaterThan(1000), reason: file);
    }
  });
}
