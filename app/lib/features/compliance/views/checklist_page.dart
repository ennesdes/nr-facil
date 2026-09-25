/// Tela do checklist consolidado.
///
/// Mostra barra de progresso e itens aplicáveis agrupados por NR.
/// Escopo e avisos legais ficam no sheet [ComplianceInfoSheet] (ícone na AppBar).
/// Anúncio: apenas o banner global da [HomePage] (acima da bottom nav).
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_linear_progress.dart';
import '../../../core/widgets/app_safe_area.dart';
import '../../../core/widgets/app_scroll_bottom_inset.dart';
import '../../../core/widgets/empty_state.dart';
import '../controllers/checklist_controller.dart';
import '../controllers/company_profile_controller.dart';
import 'company_profile_page.dart';
import '../compliance_copy.dart';
import 'widgets/checklist_item_card.dart';
import 'widgets/compliance_info_sheet.dart';

class ChecklistPage extends GetView<ChecklistController> {
  const ChecklistPage({super.key});

  /// Ações exibidas na AppBar da [HomePage] quando a aba Checklist está ativa.
  static List<Widget> homeAppBarActions(BuildContext context) {
    return [
      IconButton(
        key: const ValueKey('compliance_info_button'),
        icon: const Icon(Icons.info_outline),
        tooltip: 'Sobre esta lista',
        onPressed: () => ComplianceInfoSheet.show(context),
      ),
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Editar perfil',
        onPressed: () => editProfile(context),
      ),
      IconButton(
        icon: const Icon(Icons.restart_alt),
        tooltip: 'Resetar checklist',
        onPressed: () => confirmReset(context),
      ),
    ];
  }

  static void _ensureControllerRegistered() {
    if (Get.isRegistered<ChecklistController>()) return;
    Get.put(
      ChecklistController(
        storageService: Get.find(),
        complianceService: Get.find(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllerRegistered();
    return Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.loadError.value != null) {
            final missing = controller.isProfileMissing;
            return Center(
              child: EmptyState(
                icon: missing ? Icons.business_outlined : Icons.error_outline,
                title: missing
                    ? ComplianceCopy.profileMissingTitle
                    : 'Erro ao carregar',
                body: missing
                    ? ComplianceCopy.profileMissingBody
                    : controller.loadError.value ?? 'Erro desconhecido',
                actions: [
                  if (missing)
                    FilledButton(
                      onPressed: () => editProfile(context),
                      child: const Text('Configurar minha empresa'),
                    )
                  else
                    FilledButton(
                      onPressed: () => controller.reload(),
                      child: const Text('Tentar novamente'),
                    ),
                ],
              ),
            );
          }

          if (controller.applicableItems.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: ComplianceCopy.emptyItemsTitle,
                body: ComplianceCopy.emptyItemsBody,
                actions: [
                  FilledButton(
                    onPressed: () => editProfile(context),
                    child: const Text('Editar perfil'),
                  ),
                ],
              ),
            );
          }

          return AppScaffoldBody(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      ComplianceCopy.screenSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildProgressSection(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildItemsList(context),
                  const AppScrollBottomInset(),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seu progresso',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Obx(
                () => Text(
                  '${controller.checkedCount}/${controller.totalCount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () {
              final fraction =
                  (controller.completionPercentage / 100).clamp(0.0, 1.0);
              return AppLinearProgress(value: fraction);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Text(
              '${controller.completionPercentage}% completo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ComplianceCopy.itemsSectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => Column(
              children: [
                for (final nrId in controller.nrIds)
                  _buildNrSection(context, nrId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNrSection(BuildContext context, String nrId) {
    return Obx(
      () {
        final items = controller.itemsByNr[nrId] ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nrId.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '${items.where((i) => controller.isItemChecked(i)).length}/${items.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Items da NR
            for (final item in items) ChecklistItemCard(item: item),

            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }

  /// Abre a tela de perfil e recarrega o checklist ao voltar (perfil pode ter mudado).
  static Future<void> editProfile(BuildContext context) async {
    CompanyProfileController.ensureRegistered();
    await Get.to(() => const CompanyProfilePage());
    if (!Get.isRegistered<ChecklistController>()) return;
    await Get.find<ChecklistController>().reload();
  }

  static Future<void> confirmReset(BuildContext context) async {
    if (!Get.isRegistered<ChecklistController>()) return;
    final checklistController = Get.find<ChecklistController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar checklist?'),
        content: const Text(
          'Todos os itens marcados como verificados voltam a ficar pendentes. '
          'O perfil da empresa não é afetado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await checklistController.resetAllChecked();
    }
  }
}
