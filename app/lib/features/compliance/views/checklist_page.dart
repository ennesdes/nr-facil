/// Tela do checklist consolidado.
///
/// Mostra:
/// - Disclaimer de data de atualização
/// - Barra de progresso
/// - Itens aplicáveis agrupados por NR
/// - Banner de anúncio (PersistentBannerAd)
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_safe_area.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../features/ads/widgets/persistent_banner_ad.dart';
import '../controllers/checklist_controller.dart';
import '../controllers/company_profile_controller.dart';
import 'company_profile_page.dart';
import 'widgets/checklist_item_card.dart';
import 'widgets/compliance_disclaimer_banner.dart';

class ChecklistPage extends GetView<ChecklistController> {
  const ChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar perfil',
            onPressed: () => _editProfile(context),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Resetar checklist',
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: Obx(
        () {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.loadError.value != null) {
            return Center(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Erro ao carregar',
                body: controller.loadError.value ?? 'Erro desconhecido',
              ),
            );
          }

          if (controller.applicableItems.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.check_circle_outline,
                title: 'Nenhum item aplicável',
                body: controller.profile.value?.riskFactors.isEmpty ?? true
                    ? 'Marque fatores de risco no perfil para ver itens de conformidade'
                    : 'Nenhum item de conformidade encontrado para seu perfil',
                actions: [
                  ElevatedButton(
                    onPressed: () => _editProfile(context),
                    child: const Text('Editar Perfil'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              const ComplianceDisclaimerBanner(),
              Expanded(
                child: AppScaffoldBody(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        _buildProgressSection(context),
                        const SizedBox(height: AppSpacing.lg),
                        _buildItemsList(context),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PersistentBannerAd(),
                ],
              ),
            ],
          );
        },
      ),
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
            () => LinearProgressIndicator(
              value: controller.completionPercentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => Text(
              '${controller.completionPercentage}% completo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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
            'Itens de conformidade',
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da NR com contador
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
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
                          color: Colors.grey[600],
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
  Future<void> _editProfile(BuildContext context) async {
    CompanyProfileController.ensureRegistered();
    await Get.to(() => const CompanyProfilePage());
    await controller.reload();
  }

  Future<void> _confirmReset(BuildContext context) async {
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
      await controller.resetAllChecked();
    }
  }
}
