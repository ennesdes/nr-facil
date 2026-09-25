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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final factors = controller.availableRiskFactors;

      if (factors.isEmpty) {
        return Text(
          'Nenhum fator de risco disponível',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }

      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fatores de risco da sua empresa',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Selecione os que se aplicam à sua realidade',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < factors.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.35),
                  ),
                Obx(
                  () => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      factors[i].label,
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: controller.isRiskFactorSelected(factors[i].id),
                    onChanged: (_) =>
                        controller.toggleRiskFactor(factors[i].id),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
