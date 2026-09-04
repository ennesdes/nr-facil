import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_system_ui.dart';
import 'app_typography.dart';

/// Temas light e dark do NR Fácil.
abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.surfaceContainer,
          surfaceContainer: AppColors.surfaceContainer,
          surfaceContainerHigh: AppColors.surfaceContainerHigh,
          surfaceContainerHighest: AppColors.surfaceBright,
          outline: AppColors.outline,
          error: AppColors.error,
          onError: AppColors.onError,
        ),
        semanticColors: AppSemanticColors.light,
        appBarBackground: AppColors.surface,
        cardColor: AppColors.surfaceBright,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryDark,
          onPrimary: AppColors.onPrimaryDark,
          primaryContainer: AppColors.primaryContainerDark,
          onPrimaryContainer: AppColors.onPrimaryContainerDark,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.onSurfaceDark,
          onSurfaceVariant: AppColors.onSurfaceVariantDark,
          surfaceContainerLowest: AppColors.surfaceDark,
          surfaceContainerLow: AppColors.surfaceContainerDark,
          surfaceContainer: AppColors.surfaceContainerDark,
          surfaceContainerHigh: AppColors.surfaceContainerHighDark,
          surfaceContainerHighest: AppColors.surfaceContainerHighDark,
          outline: AppColors.outlineDark,
          error: AppColors.errorDark,
          onError: AppColors.onPrimary,
        ),
        semanticColors: AppSemanticColors.dark,
        appBarBackground: AppColors.surfaceContainerDark,
        cardColor: AppColors.surfaceContainerDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required AppSemanticColors semanticColors,
    required Color appBarBackground,
    required Color cardColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerColor: colorScheme.outline,
      textTheme: AppTypography.textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: false,
        backgroundColor: appBarBackground,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: AppSystemUi.overlayFor(
          brightness: brightness,
          surface: colorScheme.surface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minVerticalPadding: AppSpacing.sm,
        iconColor: colorScheme.onSurfaceVariant,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
      extensions: [semanticColors],
    );
    return base;
  }
}
