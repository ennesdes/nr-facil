import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Badge semântico para estados de NR (atualizada, revogada, baixada).
class NrBadge extends StatelessWidget {
  final NrBadgeVariant variant;

  const NrBadge({required this.variant, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semanticColors;
    final colorScheme = theme.colorScheme;

    final (background, foreground, label) = switch (variant) {
      NrBadgeVariant.update => (
          semantics.warningContainer,
          semantics.warning,
          'Atualizada',
        ),
      NrBadgeVariant.revoked => (
          Colors.transparent,
          semantics.revoked,
          'Revogada',
        ),
      NrBadgeVariant.downloaded => (
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
          'Baixada',
        ),
    };

    final textStyle = variant == NrBadgeVariant.revoked
        ? theme.textTheme.labelSmall?.copyWith(color: foreground)
        : theme.textTheme.labelMedium?.copyWith(color: foreground);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: variant == NrBadgeVariant.revoked
            ? Border.all(color: semantics.revoked)
            : null,
      ),
      child: Text(label, style: textStyle),
    );
  }
}

enum NrBadgeVariant { update, revoked, downloaded }
