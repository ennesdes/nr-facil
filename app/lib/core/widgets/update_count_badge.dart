import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:nrfacil/core/constants/semantics/management_semantics_ids.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Contagem de atualizações pendentes (ex.: sino, filtros).
class UpdateCountBadge extends StatelessWidget {
  final int count;
  final double minSize;

  const UpdateCountBadge({required this.count, this.minSize = 18, super.key});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final semantics = context.semanticColors;

    return Semantics(
      identifier: ManagementSemanticsIds.updatesBadge,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: semantics.warningContainer,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: semantics.warning.withValues(alpha: 0.35),
          ),
        ),
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: semantics.onWarningContainer,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
