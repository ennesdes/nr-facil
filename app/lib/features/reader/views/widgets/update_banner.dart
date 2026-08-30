import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

/// Banner dispensável indicando que a NR foi atualizada.
///
/// Exibe um ícone de atualização, texto curto e dois CTA:
/// - Botão X: fechar o banner (dispensa sem visualizar)
/// - Botão "Ver o que mudou": abrir bottom sheet com itens granulares
///
/// Tanto disparir quanto abrir o CTA chama dismissUpdateBanner(),
/// que marca a NR como vista e oculta o banner.
///
/// Se a UpdateEntry não houver itens granulares, mostra o summary
/// como texto simples dentro do bottom sheet.
class UpdateBanner extends GetView<NRReaderController> {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Ícone de atualização
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.update,
                color: Colors.blue[700],
              ),
            ),

            // Texto: "Esta NR foi atualizada"
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Esta NR foi atualizada',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Toque para ver o que mudou',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // CTA "Ver o que mudou" (link azul)
            TextButton(
              onPressed: () => _showUpdateDetails(context),
              child: const Text('Ver'),
            ),

            // Botão de fechar (X)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Dispensar',
              onPressed: controller.dismissUpdateBanner,
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  /// Abrir bottom sheet com detalhes da atualização.
  void _showUpdateDetails(BuildContext context) {
    final updateEntry = controller.getUpdateEntry();

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
              // Header com título
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
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                  ],
                ),
              ),

              // Conteúdo: items ou summary
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildUpdateContent(context, updateEntry),
                ),
              ),

              // Botão de fechar
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

    // Também dismissir o banner ao abrir o CTA (se ainda não foi)
    controller.dismissUpdateBanner();
  }

  /// Construir conteúdo do bottom sheet: items ou summary.
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

    // Se houver items, mostrar a lista granular
    if (updateEntry.items.isNotEmpty) {
      return UpdateItemsList(items: updateEntry.items);
    }

    // Fallback: mostrar summary como texto
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

  /// Formatar data para exibição (ex: "26 de agosto de 2026")
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
