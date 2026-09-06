import 'dart:math';

import 'package:flutter/material.dart';

/// Breakpoint (menor lado) para layout de tablet.
const double kTabletBreakpoint = 600;

/// Largura máxima do conteúdo de leitura em telas largas.
const double kReaderContentMaxWidth = 720;

/// Largura máxima do drawer de índice em tablets.
const double kDrawerMaxWidth = 400;

/// Largura abaixo da qual a AppBar do leitor colapsa ações extras.
const double kCompactWidthBreakpoint = 400;

/// Largura máxima de listas (home, busca, ajustes) em tablets.
const double kListContentMaxWidth = 840;

/// Utilitários de layout responsivo para telefones e tablets.
class ResponsiveLayout {
  ResponsiveLayout._();

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= kTabletBreakpoint;
  }

  static bool isCompactWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < kCompactWidthBreakpoint;
  }

  /// Largura do drawer de índice — proporcional no telefone, limitada no tablet.
  static double drawerWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (isTablet(context)) {
      return min(width * 0.45, kDrawerMaxWidth);
    }
    return width * 0.88;
  }

  /// Padding horizontal do leitor; centraliza o texto em telas largas.
  static double readerHorizontalPadding(
    BuildContext context, {
    double base = 20,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= kReaderContentMaxWidth) return base;
    return max(base, (width - kReaderContentMaxWidth) / 2);
  }

  /// Largura máxima para colunas de lista em tablets.
  static double listContentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (!isTablet(context)) return width;
    return min(width, kListContentMaxWidth);
  }

  /// Indentação de itens normativos, reduzida em telas muito estreitas.
  static double readerItemIndent(BuildContext context, int depth) {
    final perLevel = MediaQuery.sizeOf(context).width < 360 ? 10.0 : 14.0;
    return (depth - 1) * perLevel;
  }
}
