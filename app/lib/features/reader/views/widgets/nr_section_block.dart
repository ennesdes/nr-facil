import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_block_renderer.dart';

/// Bloco plano de uma seção normativa — leitura contínua sem cards.
class NrSectionBlock extends StatelessWidget {
  final NrSection section;
  final double fontSize;
  final String nrId;
  final String? highlightQuery;
  final GlobalKey Function(String sectionId, int blockIndex) blockKeyFor;
  final bool showTopDivider;

  const NrSectionBlock({
    required this.section,
    required this.fontSize,
    required this.nrId,
    required this.blockKeyFor,
    this.highlightQuery,
    this.showTopDivider = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sectionLabel = formatSectionTitle(section.number, section.title);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kReaderHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTopDivider) ...[
            const SizedBox(height: AppSpacing.xl),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
          ],
          HighlightedText(
            text: sectionLabel,
            highlight: highlightQuery,
            style: readerSectionTitleStyle(context, fontSize),
          ),
          const SizedBox(height: AppSpacing.md),
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
    );
  }
}
