/// Informações de escopo e limitações — fora do fluxo principal do checklist.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_modal_bottom_sheet.dart';
import '../../../../core/services/compliance_service.dart';
import '../../compliance_copy.dart';
import '../../controllers/checklist_controller.dart';

class ComplianceInfoSheet {
  ComplianceInfoSheet._();

  static Future<void> show(BuildContext context) {
    final updatedAt = Get.isRegistered<ChecklistController>()
        ? Get.find<ChecklistController>().atualizadoEm
        : Get.find<ComplianceService>().atualizadoEm;

    return showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final muted = theme.colorScheme.onSurfaceVariant;

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ComplianceCopy.infoSheetTitle,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ComplianceCopy.infoSheetScope(updatedAt),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ComplianceCopy.infoSheetDisclaimer,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  ComplianceCopy.coverageTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final line in ComplianceCopy.coverageBullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  ComplianceCopy.progressHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Entendi'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
