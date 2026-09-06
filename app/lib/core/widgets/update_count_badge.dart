import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Contagem de atualizações pendentes (ex.: sino, filtros).
class UpdateCountBadge extends StatelessWidget {
  final int count;
  final double minSize;

  const UpdateCountBadge({
    required this.count,
    this.minSize = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final semantics = context.semanticColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4.5,
        vertical: 2.5,
      ),
      decoration: BoxDecoration(
        color: semantics.warning,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 1.5,
        ),
      ),
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: semantics.onWarningContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
