import 'package:flutter/material.dart';

import '../../../../core/services/search_service.dart';
import '../../../reader/utils/text_utils.dart';
import '../../../reader/views/widgets/highlighted_text.dart';

/// Tile de um resultado de busca.
///
/// Exibe:
/// - Título da NR
/// - Heading da seção
/// - Snippet do texto com negrito Markdown e termo de busca destacado
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        isThreeLine: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.nrTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              stripInlineMarkup(result.chunk.heading),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
            HighlightedText(
              text: extractMarkdownSnippet(
                result.chunk.text,
                query: searchQuery,
              ),
              highlight: searchQuery,
              preserveBold: true,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
