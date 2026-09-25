/// Tela de cadastro/edição do perfil da empresa.
///
/// Permite ao usuário informar:
/// - Porte (número de funcionários)
/// - Atividade/setor
/// - Fatores de risco aplicáveis
///
/// Ao salvar, navega para o checklist consolidado.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_safe_area.dart';
import '../../../core/widgets/app_scroll_bottom_inset.dart';
import '../compliance_copy.dart';
import '../controllers/company_profile_controller.dart';
import 'widgets/risk_factor_form.dart';

class CompanyProfilePage extends GetView<CompanyProfileController> {
  const CompanyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil'), centerTitle: false),
      body: AppScaffoldBody(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroText(context),
                const SizedBox(height: AppSpacing.lg),
                _buildPorteDropdown(context),
                const SizedBox(height: AppSpacing.lg),
                _buildAtividadeDropdown(context),
                const SizedBox(height: AppSpacing.lg),
                const RiskFactorForm(),
                const SizedBox(height: AppSpacing.lg),
                _buildErrorMessage(context),
                const SizedBox(height: AppSpacing.lg),
                _buildSaveButton(),
                _buildClearButton(context),
                const AppScrollBottomInset(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return Obx(
      () => controller.isProfileSaved.value
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _confirmClear(context),
                  child: const Text('Limpar dados da empresa'),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar dados da empresa?'),
        content: const Text(
          'Porte, atividade e fatores de risco cadastrados serão apagados. '
          'Os itens do checklist que você já marcou como verificados não são '
          'afetados — use "Resetar checklist" na tela de checklist se quiser '
          'limpar isso também. Você pode preencher um novo perfil em seguida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar dados'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.clearProfile();
    }
  }

  Widget _buildIntroText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vamos conhecer sua empresa',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          ComplianceCopy.profileIntro,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPorteDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Porte da empresa',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.porteSelected.value.isEmpty
                ? null
                : controller.porteSelected.value,
            hint: const Text('Selecione o porte'),
            items: CompanyProfileController.porteOptions.map((option) {
              return DropdownMenuItem(value: option, child: Text(option));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.porteSelected.value = value;
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtividadeDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Atividade/setor', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Obx(
          () => DropdownButtonFormField<String>(
            initialValue: controller.segmentoIdSelected.value.isEmpty
                ? null
                : controller.segmentoIdSelected.value,
            hint: const Text('Selecione a atividade'),
            items: controller.availableSegments.map((segment) {
              return DropdownMenuItem(
                value: segment.id,
                child: Text(segment.label),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.segmentoIdSelected.value = value;
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final message = controller.saveError.value;
      if (message == null) return const SizedBox.shrink();

      final colorScheme = theme.colorScheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onErrorContainer,
          ),
        ),
      );
    });
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(
        () => FilledButton(
          onPressed: controller.isSaving.value ? null : controller.saveProfile,
          child: controller.isSaving.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar Perfil'),
        ),
      ),
    );
  }
}
