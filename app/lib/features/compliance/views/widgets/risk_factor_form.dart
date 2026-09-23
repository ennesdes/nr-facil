/// Widget para seleção de fatores de risco.
///
/// Exibe checkboxes dinamicamente carregados da lista de fatores de risco
/// do dataset de conformidade.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../controllers/company_profile_controller.dart';

class RiskFactorForm extends StatelessWidget {
  const RiskFactorForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CompanyProfileController>();

    return Obx(
      () {
        final factors = controller.availableRiskFactors;

        if (factors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Nenhum fator de risco disponível',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Fatores de risco da sua empresa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Selecione os que se aplicam à sua realidade',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...factors.map((factor) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Obx(
                  () => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      factor.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    value: controller.isRiskFactorSelected(factor.id),
                    onChanged: (_) => controller.toggleRiskFactor(factor.id),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
