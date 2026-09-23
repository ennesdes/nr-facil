/// Card de um item do checklist.
///
/// Mostra:
/// - Número e título do item
/// - Badge de infração com gradação (quando aplicável)
/// - Explicação curada
/// - Checkbox de verificação
/// - Botão para abrir no leitor
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/compliance_item.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/reader/utils/reader_navigation.dart';
import '../../compliance_copy.dart';
import '../../controllers/checklist_controller.dart';

class ChecklistItemCard extends StatelessWidget {
  final ComplianceItem item;

  const ChecklistItemCard({
    required this.item,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChecklistController>();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: NR + título + badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.nrId.toUpperCase()} - Item ${item.itemNumber}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.titulo,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (item.infracao) _buildInfracaoBadge(context, item),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Explicação
            Text(
              item.explicacao,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
            ),

            if (item.infracao) ...[
              const SizedBox(height: AppSpacing.md),
              _buildNr28Reference(context, item),
            ],

            const SizedBox(height: AppSpacing.md),

            // Responsável
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Resp.: ${item.responsavel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Checkbox + botão "Ver na norma"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Row(
                    children: [
                      Checkbox(
                        value: controller.isItemChecked(item),
                        onChanged: (_) => controller.toggleItemChecked(item),
                      ),
                      Text(
                        controller.isItemChecked(item)
                            ? 'Verificado'
                            : 'Verificar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: controller.isItemChecked(item)
                                  ? FontWeight.bold
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Compartilhar item',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: item.toShareText()),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openInReader(item),
                      child: const Text('Ver na norma'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNr28Reference(BuildContext context, ComplianceItem item) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ComplianceCopy.nr28BaseLine,
          style: theme.textTheme.labelSmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (item.codigoInfracao != null && item.codigoInfracao!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Código de infração: ${item.codigoInfracao}',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        ],
      ],
    );
  }

  Widget _buildInfracaoBadge(BuildContext context, ComplianceItem item) {
    final hasGradacao = item.gradacao != null;
    final label = item.gradacao ?? 'Infração';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Infração',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (hasGradacao) ...[
            const SizedBox(height: 2),
            Text(
              item.gradacaoLabel ?? label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
          ],
          if (item.tipoLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              item.tipoLabel!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  void _openInReader(ComplianceItem item) {
    ReaderNavigation.open(
      nrId: item.nrId,
      initialAnchor: item.readerAnchorId,
    );
  }
}
