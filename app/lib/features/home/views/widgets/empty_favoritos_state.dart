import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';

/// Estado vazio para quando não há NRs favoritadas.
///
/// Exibe mensagem e sugestões de NRs populares (NR-06, NR-10, NR-18)
/// como chips/botões clicáveis — somente mostrar se existirem no manifest.
class EmptyFavoritosState extends StatelessWidget {
  final Manifest? manifest;

  const EmptyFavoritosState({
    this.manifest,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Sem favoritos ainda',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Adicione NRs aos favoritos para acessá-las rapidamente',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (manifest != null) ...[
                Text(
                  'Sugestões populares:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSuggestionChip(context, 'NR-06', manifest!),
                    _buildSuggestionChip(context, 'NR-10', manifest!),
                    _buildSuggestionChip(context, 'NR-18', manifest!),
                  ].whereType<Widget>().toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construir chip de sugestão de NR se ela existir no manifest.
  Widget? _buildSuggestionChip(
    BuildContext context,
    String nrId,
    Manifest manifest,
  ) {
    final entry = manifest.findNr(nrId);
    if (entry == null || entry.isRevoked) {
      return null; // Não mostrar se não existir ou estiver revogada
    }

    return ActionChip(
      onPressed: () {
        // Abrir leitor dessa NR
        Get.to(
          () => NRReaderPage(nrId: nrId),
          binding: ReaderBinding(nrId: nrId),
        );
      },
      label: Text(nrId),
      avatar: const Icon(Icons.open_in_new, size: 18),
    );
  }
}
