import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

/// Banner dispensável indicando que a NR foi atualizada.
class UpdateBanner extends GetView<NRReaderController> {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final semantics = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: semantics.infoContainer,
        border: Border(
          bottom: BorderSide(color: semantics.info.withValues(alpha: 0.4)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.update, color: semantics.info),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esta NR foi atualizada',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Toque para ver o que mudou',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: semantics.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showUpdateDetails(context),
              child: const Text('Ver'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
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

    showModalBottomSheet(
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
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O que mudou',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (updateEntry != null && updateEntry.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
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
                padding: const EdgeInsets.all(16),
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

    controller.dismissUpdateBanner();
  }

  Widget _buildUpdateContent(BuildContext context, UpdateEntry? updateEntry) {
    if (updateEntry == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.only(top: 12),
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
                    padding: const EdgeInsets.only(top: 4),
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
