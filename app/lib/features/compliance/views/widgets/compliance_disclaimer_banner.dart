/// Banner de disclaimer mostrando a data de atualização do dataset.
///
/// Avisa que o conteúdo pode estar desatualizado e que não substitui
/// consulta a profissional de SST ou ao texto oficial.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../controllers/checklist_controller.dart';

class ComplianceDisclaimerBanner extends StatelessWidget {
  const ComplianceDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChecklistController>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border(
          bottom: BorderSide(color: Colors.amber[200]!),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aviso importante',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900],
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Itens alinhados ao Anexo II da NR-28 (possível autuação). '
                      'Regras atualizadas em ${controller.atualizadoEm}. '
                      'Conteúdo curado — pode estar desatualizado. '
                      'Não substitui especialista de SST nem o texto oficial da norma.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber[900],
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
