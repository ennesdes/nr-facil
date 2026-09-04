import 'package:flutter/material.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Altura de linha confortável para leitura prolongada.
const double kReaderLineHeight = 1.72;

/// Padding horizontal padrão do corpo do leitor.
const double kReaderHorizontalPadding = 20;

/// Formata título de seção para exibição legível.
String formatSectionTitle(String number, String title) {
  final cleanTitle = formatNrTitleForDisplay(stripInlineMarkup(title));
  if (number.isEmpty) return cleanTitle;
  if (cleanTitle.isEmpty) return number;
  return '$number $cleanTitle';
}

/// Estilo do corpo normativo no leitor.
TextStyle readerBodyStyle(BuildContext context, double fontSize) {
  return Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: fontSize,
        color: Theme.of(context).colorScheme.onSurface,
        height: kReaderLineHeight,
        letterSpacing: 0.1,
      );
}

/// Estilo de título de seção (6.1 Objetivo).
TextStyle readerSectionTitleStyle(BuildContext context, double fontSize) {
  return Theme.of(context).textTheme.titleMedium!.copyWith(
        fontSize: fontSize + 3,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.35,
        letterSpacing: 0.15,
      );
}

/// Estilo de número de item normativo.
TextStyle readerItemNumberStyle(BuildContext context, double fontSize) {
  return Theme.of(context).textTheme.titleSmall!.copyWith(
        fontSize: fontSize + 1,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.25,
        letterSpacing: 0.2,
      );
}

/// Espaçamento inferior para o indicador de posição flutuante.
const double kReaderBottomScrollPadding = 84;
