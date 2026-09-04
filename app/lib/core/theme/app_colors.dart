import 'package:flutter/material.dart';

/// Constantes de cor da paleta NR Fácil.
///
/// Preferir [ColorScheme] e [AppSemanticColors] nos widgets; usar esta classe
/// apenas na construção do tema.
abstract final class AppColors {
  // Light
  static const primary = Color(0xFF0F5C4E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD4EDE6);
  static const onPrimaryContainer = Color(0xFF0A3D34);
  static const secondary = Color(0xFF1E3A5F);
  static const onSecondary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFAFBFC);
  static const onSurface = Color(0xFF1A1C1E);
  static const onSurfaceVariant = Color(0xFF5C6670);
  static const surfaceContainer = Color(0xFFF0F2F4);
  static const surfaceContainerHigh = Color(0xFFE8EAED);
  static const outline = Color(0xFFC5CDD4);
  static const error = Color(0xFFC62828);
  static const onError = Color(0xFFFFFFFF);

  // Dark
  static const primaryDark = Color(0xFF4DB6A0);
  static const onPrimaryDark = Color(0xFF0A3D34);
  static const primaryContainerDark = Color(0xFF0F5C4E);
  static const onPrimaryContainerDark = Color(0xFFD4EDE6);
  static const surfaceDark = Color(0xFF121212);
  static const onSurfaceDark = Color(0xFFE8EAED);
  static const onSurfaceVariantDark = Color(0xFF9AA0A6);
  static const surfaceContainerDark = Color(0xFF1E1E1E);
  static const surfaceContainerHighDark = Color(0xFF2A2A2A);
  static const outlineDark = Color(0xFF5C6670);
  static const errorDark = Color(0xFFEF5350);

  // Semantic — light
  static const success = Color(0xFF2E7D4F);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFEF3C7);
  static const info = Color(0xFF1565A8);
  static const infoContainer = Color(0xFFE3F0FA);
  static const revoked = Color(0xFF9E9E9E);

  // Semantic — dark
  static const successDark = Color(0xFF66BB6A);
  static const warningDark = Color(0xFFFFB74D);
  static const warningContainerDark = Color(0xFF4A3F1A);
  static const infoDark = Color(0xFF64B5F6);
  static const infoContainerDark = Color(0xFF1A2F42);
  static const revokedDark = Color(0xFF757575);
}
