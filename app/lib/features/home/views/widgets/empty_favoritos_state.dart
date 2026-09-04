import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';

/// Estado vazio para quando não há NRs favoritadas.
class EmptyFavoritosState extends StatelessWidget {
  final Manifest? manifest;

  const EmptyFavoritosState({
    this.manifest,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.star_outline,
      title: 'Sem favoritos ainda',
      body: 'Adicione normas aos favoritos para acessá-las rapidamente',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Get.find<HomeController>().selectTab(HomeController.tabNormas);
          },
          icon: const Icon(Icons.library_books_outlined),
          label: const Text('Explorar normas'),
        ),
        if (manifest != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sugestões populares:',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip(context, 'NR-06', manifest!),
              _buildSuggestionChip(context, 'NR-10', manifest!),
              _buildSuggestionChip(context, 'NR-18', manifest!),
            ].whereType<Widget>().toList(),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuggestionChip(
    BuildContext context,
    String nrId,
    Manifest manifest,
  ) {
    final entry = manifest.findNr(nrId);
    if (entry == null || entry.isRevoked) {
      return null;
    }

    return ActionChip(
      onPressed: () {
        ReaderNavigation.open(nrId: nrId);
      },
      label: Text(nrId),
      avatar: const Icon(Icons.open_in_new, size: 18),
    );
  }
}
