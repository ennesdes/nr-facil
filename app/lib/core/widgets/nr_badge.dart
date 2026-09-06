import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Badge semântico para estados de NR (atualizada, revogada, baixada).
class NrBadge extends StatelessWidget {
  final NrBadgeVariant variant;
  final bool compact;

  const NrBadge({required this.variant, this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semanticColors;
    final colorScheme = theme.colorScheme;

    final (background, foreground, label, icon) = switch (variant) {
      NrBadgeVariant.update => (
        semantics.warningContainer,
        semantics.onWarningContainer,
        compact ? 'Atualizada' : 'Atualização disponível',
        Icons.update,
      ),
      NrBadgeVariant.revoked => (
        colorScheme.surfaceContainerHigh,
        semantics.revoked,
        'Revogada',
        null,
      ),
      NrBadgeVariant.downloaded => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        'Baixada',
        Icons.download_done,
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
            : variant == NrBadgeVariant.update
            ? Border.all(color: semantics.warning.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

enum NrBadgeVariant { update, revoked, downloaded }
