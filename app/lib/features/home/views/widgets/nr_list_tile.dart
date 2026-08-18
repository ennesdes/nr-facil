import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';

/// Tile para exibir uma NR em lista.
///
/// Mostra:
/// - Título da NR
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

  const NrListTile({
    required this.nrEntry,
    required this.isFavorite,
    required this.hasUpdate,
    required this.onTap,
    required this.onToggleFavorite,
    this.isRevoked = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Row(
        children: [
          Expanded(
            child: Text(
              nrEntry.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (hasUpdate)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '🆕',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          if (isRevoked)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Revogada',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
      trailing: isRevoked
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
