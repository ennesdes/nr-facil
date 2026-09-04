import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia Inter conforme [docs/design-system.md].
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme colorScheme) {
    final source = ThemeData(brightness: colorScheme.brightness).textTheme;
    final scaled = _scaledTextTheme(source);

    final themed = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.interTextTheme(scaled)
        : scaled;

    return themed.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  static TextTheme _scaledTextTheme(TextTheme source) {
    return source.copyWith(
      displaySmall: _style(source.displaySmall, 28, FontWeight.w600, 1.2),
      titleLarge: _style(source.titleLarge, 20, FontWeight.w600, 1.3),
      titleMedium: _style(source.titleMedium, 16, FontWeight.w600, 1.4),
      titleSmall: _style(source.titleSmall, 14, FontWeight.w600, 1.4),
      bodyLarge: _style(source.bodyLarge, 16, FontWeight.w400, 1.5),
      bodyMedium: _style(source.bodyMedium, 14, FontWeight.w400, 1.5),
      bodySmall: _style(source.bodySmall, 12, FontWeight.w400, 1.4),
      labelSmall: _style(source.labelSmall, 11, FontWeight.w600, 1.3),
      labelMedium: _style(source.labelMedium, 12, FontWeight.w600, 1.3),
    );
  }

  static TextStyle? _style(
    TextStyle? base,
    double size,
    FontWeight weight,
    double height,
  ) {
    return (base ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: null,
    );
  }
}
