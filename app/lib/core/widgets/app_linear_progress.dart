import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Barra de progresso determinada com trilho neutro (vazio) e preenchimento no
/// token de destaque — legível em tema claro e escuro.
class AppLinearProgress extends StatelessWidget {
  /// Progresso entre 0 e 1. Use `null` apenas para estado indeterminado.
  final double? value;
  final double minHeight;

  const AppLinearProgress({this.value, this.minHeight = 8, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.xs),
      child: LinearProgressIndicator(
        value: value,
        minHeight: minHeight,
        backgroundColor: colorScheme.surfaceContainerHigh,
        color: colorScheme.secondary,
      ),
    );
  }
}
