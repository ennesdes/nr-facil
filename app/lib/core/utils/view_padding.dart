import 'package:flutter/material.dart';

/// Utilitários para respeitar a barra de navegação e demais insets do sistema.
abstract final class ViewPadding {
  /// Padding inferior da barra de navegação / gestos do sistema.
  static double bottomOf(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Padding inferior incluindo o teclado virtual aberto.
  static double bottomWithKeyboard(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.viewInsets.bottom + mediaQuery.viewPadding.bottom;
  }

  /// Garante que [MediaQuery.padding] reflita os insets do sistema em modo
  /// edge-to-edge (Android 15+), onde [viewPadding] é a fonte confiável.
  static MediaQueryData ensureSystemPadding(MediaQueryData data) {
    return data.copyWith(padding: data.viewPadding);
  }
}
