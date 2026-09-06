import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';

/// Ações manuais da tela de Atualizações (verificar e baixar offline).
class UpdatesQuickActions extends StatelessWidget {
  final bool isChecking;
  final bool showDownloadButton;
  final VoidCallback onCheck;
  final VoidCallback onDownload;

  const UpdatesQuickActions({
    required this.isChecking,
    required this.showDownloadButton,
    required this.onCheck,
    required this.onDownload,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ações',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Verifique novidades no servidor ou baixe todo o conteúdo '
              'para uso offline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: isChecking ? null : onCheck,
              icon: const Icon(Icons.refresh),
              label: const Text('Verificar atualizações'),
            ),
            if (showDownloadButton) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: const Text('Baixar tudo para offline'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
