import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/sync_progress.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';

/// Painel de progresso para ações da tela de Atualizações.
class UpdatesActionProgress extends StatelessWidget {
  final bool isChecking;
  final BulkSyncProgress? downloadProgress;
  final VoidCallback? onDownloadTap;

  const UpdatesActionProgress({
    required this.isChecking,
    this.downloadProgress,
    this.onDownloadTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return _ProgressCard(
        icon: Icons.sync,
        title: 'Verificando atualizações',
        subtitle: 'Consultando novas versões no servidor…',
        indeterminate: true,
      );
    }

    final progress = downloadProgress;
    if (progress == null || !progress.isActive) {
      return const SizedBox.shrink();
    }

    if (progress.phase == BulkSyncPhase.preparing) {
      return _ProgressCard(
        icon: Icons.download_for_offline_outlined,
        title: 'Preparando download',
        subtitle: 'Carregando lista de normas…',
        indeterminate: true,
        onTap: onDownloadTap,
      );
    }

    final label = progress.currentNrLabel;
    final subtitle = progress.total == 0
        ? 'Nenhuma norma pendente.'
        : label == null
            ? 'Baixando ${progress.completed} de ${progress.total} normas…'
            : 'Baixando $label (${progress.completed} de ${progress.total})…';

    return _ProgressCard(
      icon: Icons.download_for_offline_outlined,
      title: 'Baixando para offline',
      subtitle: subtitle,
      hint: onDownloadTap != null ? 'Toque para cancelar' : null,
      indeterminate: progress.total == 0,
      progress: progress.total > 0 ? progress.fraction : null,
      percentLabel: progress.total > 0 ? '${progress.percent}%' : null,
      onTap: onDownloadTap,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? hint;
  final bool indeterminate;
  final double? progress;
  final String? percentLabel;
  final VoidCallback? onTap;

  const _ProgressCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hint,
    this.indeterminate = false,
    this.progress,
    this.percentLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBar = indeterminate || progress != null;

    final card = Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 22, color: colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (percentLabel != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              percentLabel!,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          hint!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showBar) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: indeterminate ? null : progress,
                  minHeight: 4,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.22),
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: card,
      ),
    );
  }
}
