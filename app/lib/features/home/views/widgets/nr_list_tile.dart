import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';

/// Tile para exibir uma NR em lista.
///
/// Mostra:
/// - Número da NR (NR-06) + título completo em múltiplas linhas
/// - Badge "Revogada" se isRevoked
/// - Badge "🆕" se hasUpdate
/// - Ícone de estrela para toggle favorito (desabilitado se revogado)
/// - Tap handler
class NrListTile extends StatelessWidget {
  final ManifestEntry nrEntry;
  final bool isFavorite;
  final bool hasUpdate;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool isRevoked;
  final bool hideStarButton;

  const NrListTile({
    required this.nrEntry,
    required this.isFavorite,
    required this.hasUpdate,
    required this.onTap,
    required this.onToggleFavorite,
    this.isRevoked = false,
    this.hideStarButton = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nrEntry.nrLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nrEntry.title,
                  style: theme.textTheme.bodyLarge,
                ),
                if (hasUpdate || isRevoked) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasUpdate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🆕',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      if (isRevoked) ...[
                        if (hasUpdate) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Revogada',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      trailing: (isRevoked || hideStarButton)
          ? null
          : IconButton(
              icon: Icon(isFavorite ? Icons.star : Icons.star_border),
              tooltip: isFavorite
                  ? 'Remover dos favoritos'
                  : 'Adicionar aos favoritos',
              onPressed: onToggleFavorite,
            ),
    );
  }
}
