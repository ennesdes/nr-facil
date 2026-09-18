import 'package:flutter/material.dart';
import 'package:nrfacil/core/constants/semantics/management_semantics_ids.dart';
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
    final checkIsPrimary = !showDownloadButton;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          identifier: ManagementSemanticsIds.checkForUpdatesButton,
          button: true,
          enabled: !isChecking,
          child: _CheckUpdatesButton(
            isChecking: isChecking,
            isPrimary: checkIsPrimary,
            onPressed: isChecking ? null : onCheck,
          ),
        ),
        if (showDownloadButton) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            identifier: ManagementSemanticsIds.downloadOfflineButton,
            button: true,
            child: FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text('Baixar tudo para offline'),
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckUpdatesButton extends StatelessWidget {
  final bool isChecking;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _CheckUpdatesButton({
    required this.isChecking,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = const Text('Verificar atualizações');
    final icon = isChecking
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : const Icon(Icons.refresh);

    if (isPrimary) {
      return FilledButton.icon(onPressed: onPressed, icon: icon, label: label);
    }

    return OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label);
  }
}
