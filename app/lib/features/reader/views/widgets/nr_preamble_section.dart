import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_block_renderer.dart';

/// Preâmbulo colapsável: publicação, alterações e sumário.
class NrPreambleSection extends StatelessWidget {
  final NrPreamble preamble;
  final double fontSize;
  final bool isDarkMode;
  final String nrId;
  final bool isExpanded;
  final String? highlightQuery;
  final int? highlightBlockIndex;
  final GlobalKey Function(String sectionId, int blockIndex) blockKeyFor;

  const NrPreambleSection({
    required this.preamble,
    required this.fontSize,
    required this.isDarkMode,
    required this.nrId,
    required this.isExpanded,
    required this.blockKeyFor,
    this.highlightQuery,
    this.highlightBlockIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (preamble.blocks.isEmpty) return const SizedBox.shrink();

    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
          ),
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
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            subtitle: Text(
              'Portarias, alterações e sumário',
              style: TextStyle(fontSize: fontSize - 2, color: textColor),
            ),
            children: [
              for (var i = 0; i < preamble.blocks.length; i++)
                KeyedSubtree(
                  key: blockKeyFor('preamble', i),
                  child: NrBlockRenderer(
                    block: preamble.blocks[i],
                    fontSize: fontSize,
                    isDarkMode: isDarkMode,
                    nrId: nrId,
                    highlightQuery: highlightQuery,
                    isHighlighted: highlightBlockIndex == i,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
