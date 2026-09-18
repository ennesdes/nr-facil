import 'package:flutter/material.dart';
import 'package:nrfacil/core/constants/semantics/management_semantics_ids.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_filter_chip.dart';

/// Ações manuais da tela de Atualizações (verificar e baixar offline).
class UpdatesQuickActions extends StatelessWidget {
  final bool isChecking;
  final bool showDownloadButton;
  final VoidCallback onCheck;
  final VoidCallback onDownload;
  final bool centered;

  const UpdatesQuickActions({
    required this.isChecking,
    required this.showDownloadButton,
    required this.onCheck,
    required this.onDownload,
    this.centered = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final chips = [
      Semantics(
        identifier: ManagementSemanticsIds.checkForUpdatesButton,
        child: AppFilterChip(
          label: 'Verificar atualizações',
          icon: Icons.refresh,
          emphasized: !isChecking,
          selected: isChecking,
          enabled: !isChecking,
          onTap: onCheck,
        ),
      ),
      if (showDownloadButton)
        Semantics(
          identifier: ManagementSemanticsIds.downloadOfflineButton,
          child: AppFilterChip(
            label: 'Baixar tudo para offline',
            icon: Icons.download_for_offline_outlined,
            emphasized: true,
            onTap: onDownload,
          ),
        ),
    ];

    if (centered) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: chips,
      );
    }

    return AppFilterChipRow(
      padding: EdgeInsets.zero,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          chips[i],
        ],
      ],
    );
  }
}
