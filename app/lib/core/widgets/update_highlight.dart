import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Tokens e helpers visuais para normas com atualização pendente.
abstract final class UpdateHighlight {
  static Color accentColor(BuildContext context) =>
      context.semanticColors.warning;

  static Color backgroundColor(BuildContext context) =>
      context.semanticColors.warningContainer.withValues(alpha: 0.28);

  static Color borderColor(BuildContext context) =>
      accentColor(context).withValues(alpha: 0.45);

  /// Faixa lateral usada em listas e cards.
  static Widget leadingStripe({
    required BuildContext context,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();

    return Container(
      width: 4,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      decoration: BoxDecoration(
        color: accentColor(context),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }

  /// Fundo sutil + faixa lateral para tiles de lista.
  static Widget listShell({
    required BuildContext context,
    required bool active,
    required Widget child,
  }) {
    if (!active) return child;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor(context),
        border: Border(left: BorderSide(color: accentColor(context), width: 3)),
      ),
      child: child,
    );
  }

  /// Borda de destaque para cards (ex.: continuar leitura, atualizações).
  static BorderSide cardBorderSide({
    required BuildContext context,
    required bool active,
    required ColorScheme colorScheme,
  }) {
    if (!active) {
      return BorderSide(color: colorScheme.outline);
    }
    return BorderSide(color: borderColor(context));
  }
}
