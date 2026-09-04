import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_modal_bottom_sheet.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

/// Banner dispensável indicando que a NR foi atualizada.
class UpdateBanner extends GetView<NRReaderController> {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
              child: Icon(
                Icons.update,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esta NR foi atualizada',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Houve alterações desde sua última leitura.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showUpdateDetails(context),
                    child: const Text('Ver alterações'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Dispensar',
              onPressed: controller.dismissUpdateBanner,
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateDetails(BuildContext context) {
    final updateEntry = controller.getUpdateEntry();
    final colorScheme = Theme.of(context).colorScheme;

    showAppModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que mudou?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (updateEntry != null && updateEntry.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'Atualizado em ${_formatDate(updateEntry.createdAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildUpdateContent(context, updateEntry),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.dismissUpdateBanner();
                    },
                    child: const Text('Fechar'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUpdateContent(BuildContext context, UpdateEntry? updateEntry) {
    if (updateEntry == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Detalhes da atualização indisponíveis',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    if (updateEntry.items.isNotEmpty) {
      return UpdateItemsList(items: updateEntry.items);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (updateEntry.summary.isNotEmpty)
            Text(
              updateEntry.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (updateEntry.portaria != null && updateEntry.portaria!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm + AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portaria',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      updateEntry.portaria!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
