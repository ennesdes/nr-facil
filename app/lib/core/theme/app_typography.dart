import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia Inter conforme [docs/design-system.md].
abstract final class AppTypography {
  static TextTheme textTheme([TextTheme? base]) {
    final scaled = _scaledTextTheme(base);

    if (GoogleFonts.config.allowRuntimeFetching) {
      return GoogleFonts.interTextTheme(scaled);
    }

    return scaled;
  }

  static TextTheme _scaledTextTheme([TextTheme? base]) {
    final source = base ?? ThemeData.light().textTheme;
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
    );
  }
}
