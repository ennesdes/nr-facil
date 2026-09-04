import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_block_renderer.dart';

/// Preâmbulo colapsável: publicação, alterações e sumário.
class NrPreambleSection extends StatelessWidget {
  final NrPreamble preamble;
  final double fontSize;
  final String nrId;
  final bool isExpanded;
  final String? highlightQuery;
  final GlobalKey Function(String sectionId, int blockIndex) blockKeyFor;

  const NrPreambleSection({
    required this.preamble,
    required this.fontSize,
    required this.nrId,
    required this.isExpanded,
    required this.blockKeyFor,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (preamble.blocks.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('preamble-$isExpanded'),
            initiallyExpanded: isExpanded,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              'Publicação e histórico',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            subtitle: Text(
              'Portarias, alterações e sumário',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: fontSize - 2,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            children: [
              for (var i = 0; i < preamble.blocks.length; i++)
                KeyedSubtree(
                  key: blockKeyFor('preamble', i),
                  child: NrBlockRenderer(
                    block: preamble.blocks[i],
                    fontSize: fontSize,
                    nrId: nrId,
                    highlightQuery: highlightQuery,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
