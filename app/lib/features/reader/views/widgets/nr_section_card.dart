import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_block_renderer.dart';

/// Card recolhível de uma seção normativa — toque para expandir o conteúdo.
class NrSectionCard extends StatelessWidget {
  final NrSection section;
  final double fontSize;
  final String nrId;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final String? highlightQuery;
  final GlobalKey Function(String sectionId, int blockIndex) blockKeyFor;

  const NrSectionCard({
    required this.section,
    required this.fontSize,
    required this.nrId,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.blockKeyFor,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey('${section.id}-$isExpanded'),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: HighlightedText(
            text: section.displayTitle,
            highlight: highlightQuery,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: fontSize + 2,
                  color: colorScheme.onSurface,
                ),
          ),
          subtitle: Text(
            '${section.blocks.length} trecho(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: fontSize - 2,
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          children: [
            for (var i = 0; i < section.blocks.length; i++)
              KeyedSubtree(
                key: blockKeyFor(section.id, i),
                child: NrBlockRenderer(
                  block: section.blocks[i],
                  fontSize: fontSize,
                  nrId: nrId,
                  highlightQuery: highlightQuery,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
