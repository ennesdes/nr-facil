import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/reader/utils/preamble_info_utils.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';

/// Preâmbulo colapsável: última alteração, publicação original e histórico.
class NrPreambleSection extends StatefulWidget {
  final NrPreamble preamble;
  final ManifestEntry? nrEntry;
  final double fontSize;
  final String nrId;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final String? highlightQuery;
  final GlobalKey Function(String sectionId, int blockIndex) blockKeyFor;

  const NrPreambleSection({
    required this.preamble,
    required this.nrEntry,
    required this.fontSize,
    required this.nrId,
    required this.isExpanded,
    required this.blockKeyFor,
    this.onExpansionChanged,
    this.highlightQuery,
    super.key,
  });

  @override
  State<NrPreambleSection> createState() => _NrPreambleSectionState();
}

class _NrPreambleSectionState extends State<NrPreambleSection> {
  bool _showFullHistory = false;

  @override
  Widget build(BuildContext context) {
    if (widget.preamble.blocks.isEmpty) return const SizedBox.shrink();

    final info = parsePreambleInfo(widget.preamble, manifestEntry: widget.nrEntry);
    if (info.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = readerBodyStyle(context, widget.fontSize);
    final mutedStyle = bodyStyle.copyWith(color: colorScheme.onSurfaceVariant);
    final noteStyle = mutedStyle.copyWith(fontStyle: FontStyle.italic);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        );
    final secondaryLabelStyle = labelStyle?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final latest = info.latestAmendment;
    final previous = info.previousAmendments;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kReaderHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: colorScheme.surface.withValues(alpha: 0),
            ),
            child: ExpansionTile(
              key: ValueKey('preamble-${widget.isExpanded}'),
              initiallyExpanded: widget.isExpanded,
              onExpansionChanged: widget.onExpansionChanged,
              tilePadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              childrenPadding: const EdgeInsets.only(bottom: AppSpacing.lg),
              title: Text(
                'Publicação e histórico',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              subtitle: Text(
                _buildSubtitle(info),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (info.vigenciaNote != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: HighlightedText(
                          text: info.vigenciaNote!,
                          highlight: widget.highlightQuery,
                          style: noteStyle,
                        ),
                      ),
                    if (latest != null)
                      KeyedSubtree(
                        key: widget.blockKeyFor(
                          'preamble',
                          preambleBlockIndexFor(
                            preamble: widget.preamble,
                            info: info,
                            logicalSection: 1,
                          ),
                        ),
                        child: _PortariaBlock(
                          label: 'Última alteração',
                          entry: latest,
                          bodyStyle: bodyStyle,
                          dateStyle: mutedStyle,
                          labelStyle: labelStyle,
                          highlightQuery: widget.highlightQuery,
                        ),
                      ),
                    if (previous.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            setState(() => _showFullHistory = !_showFullHistory);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _showFullHistory
                                ? 'Ocultar histórico'
                                : 'Ver histórico completo (${previous.length})',
                          ),
                        ),
                      ),
                      if (_showFullHistory) ...[
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < previous.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(alpha: 0.35),
                              ),
                            ),
                          _PortariaBlock(
                            entry: previous[i],
                            bodyStyle: mutedStyle,
                            dateStyle: mutedStyle,
                            highlightQuery: widget.highlightQuery,
                          ),
                        ],
                      ],
                    ],
                    if (info.originalPublication != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      KeyedSubtree(
                        key: widget.blockKeyFor(
                          'preamble',
                          preambleBlockIndexFor(
                            preamble: widget.preamble,
                            info: info,
                            logicalSection: 0,
                          ),
                        ),
                        child: _PortariaBlock(
                          label: 'Publicação original',
                          entry: info.originalPublication!,
                          bodyStyle: mutedStyle,
                          dateStyle: mutedStyle,
                          labelStyle: secondaryLabelStyle,
                          highlightQuery: widget.highlightQuery,
                        ),
                      ),
                    ],
                    if (info.redacaoNote != null)
                      KeyedSubtree(
                        key: widget.blockKeyFor(
                          'preamble',
                          preambleBlockIndexFor(
                            preamble: widget.preamble,
                            info: info,
                            logicalSection: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: HighlightedText(
                            text: info.redacaoNote!,
                            highlight: widget.highlightQuery,
                            style: noteStyle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(PreambleInfo info) {
    final latest = info.latestAmendment;
    if (latest != null && latest.douDate.isNotEmpty) {
      final total = info.amendments.length;
      if (total > 1) {
        return 'Última alteração em ${latest.douDate} · $total no total';
      }
      return 'Última alteração em ${latest.douDate}';
    }

    final date = info.originalPublication?.douDate;
    if (date != null && date.isNotEmpty) {
      return 'Publicada em $date';
    }

    if (info.amendments.isNotEmpty) {
      return '${info.amendments.length} alterações';
    }

    return 'Portarias e alterações';
  }
}

class _PortariaBlock extends StatelessWidget {
  final String? label;
  final PreamblePortariaEntry entry;
  final TextStyle bodyStyle;
  final TextStyle dateStyle;
  final TextStyle? labelStyle;
  final String? highlightQuery;

  const _PortariaBlock({
    required this.entry,
    required this.bodyStyle,
    required this.dateStyle,
    this.label,
    this.labelStyle,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: labelStyle),
          const SizedBox(height: AppSpacing.xs),
        ],
        HighlightedText(
          text: entry.portaria,
          highlight: highlightQuery,
          style: bodyStyle,
        ),
        if (entry.douDate.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          HighlightedText(
            text: 'D.O.U. ${entry.douDate}',
            highlight: highlightQuery,
            style: dateStyle,
          ),
        ],
      ],
    );
  }
}
