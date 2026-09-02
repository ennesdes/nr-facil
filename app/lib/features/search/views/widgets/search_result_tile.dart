import 'package:flutter/material.dart';

import '../../../../core/services/search_service.dart';

/// Tile de um resultado de busca.
///
/// Exibe:
/// - Título da NR
/// - Heading da seção
/// - Snippet do texto com o termo de busca destacado em negrito
/// - Clicável para navegar para a seção no leitor
class SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultTile({
    required this.result,
    required this.searchQuery,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da NR
            Text(
              result.nrTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            // Heading da seção
            Text(
              result.chunk.heading,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Snippet com highlight
            _buildHighlightedSnippet(context),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// Construir snippet do texto com o termo de busca destacado.
  /// Mostra ~120 caracteres ao redor do primeiro match.
  Widget _buildHighlightedSnippet(BuildContext context) {
    final text = result.chunk.text;
    final normalizedQuery = searchQuery.toLowerCase();
    final normalizedText = text.toLowerCase();

    // Encontrar primeira ocorrência
    final index = normalizedText.indexOf(normalizedQuery);
    if (index == -1) {
      // Se não encontrou (não deve acontecer), mostrar início do texto
      return Text(
        text.length > 120 ? '${text.substring(0, 120)}...' : text,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Calcular range para snippet: 60 chars antes e depois do match
    final start = (index - 60).clamp(0, text.length);
    final end = (index + searchQuery.length + 60).clamp(0, text.length);

    String snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';

    final normalizedSnippet = snippet.toLowerCase();

    // Construir RichText com highlight (case-insensitive)
    final matchStartInSnippet = normalizedSnippet.indexOf(normalizedQuery);
    if (matchStartInSnippet == -1) {
      return Text(
        snippet,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final beforeMatch = snippet.substring(0, matchStartInSnippet);
    final match = snippet.substring(
      matchStartInSnippet,
      matchStartInSnippet + searchQuery.length,
    );
    final afterMatch = snippet.substring(matchStartInSnippet + searchQuery.length);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          TextSpan(text: afterMatch),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
