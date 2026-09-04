import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:nrfacil/features/reader/views/widgets/markdown_image_builder.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_item_row.dart';
import 'package:nrfacil/features/reader/views/widgets/searchable_markdown_body.dart';

/// Renderiza um bloco tipado do structure.json.
class NrBlockRenderer extends StatelessWidget {
  final NrBlock block;
  final double fontSize;
  final String nrId;
  final String? highlightQuery;

  const NrBlockRenderer({
    required this.block,
    required this.fontSize,
    required this.nrId,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      NrItemBlock item => NrItemRow(
          nrId: nrId,
          number: item.number,
          depth: item.depth,
          text: stripInlineMarkup(item.text),
          fontSize: fontSize,
          highlightQuery: highlightQuery,
        ),
      NrListBlock list => _buildList(context, list),
      NrTableBlock table => _buildTable(context, table),
      NrImageBlock image => _buildImage(context, image),
      NrNoteBlock note => _buildNote(context, note),
      NrParagraphBlock paragraph => _buildParagraph(context, paragraph),
    };
  }

  TextStyle _bodyStyle(BuildContext context) {
    return readerBodyStyle(context, fontSize);
  }

  Widget _buildList(BuildContext context, NrListBlock list) {
    final theme = Theme.of(context);
    final bodyStyle = _bodyStyle(context);
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${item.label})',
                    style: labelStyle,
                  ),
                ),
                Expanded(
                  child: HighlightedText(
                    text: stripInlineMarkup(item.text),
                    highlight: highlightQuery,
                    style: bodyStyle,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(BuildContext context, NrTableBlock table) {
    final tableStyle = _bodyStyle(context).copyWith(fontSize: fontSize - 1);
    final headStyle = tableStyle.copyWith(fontWeight: FontWeight.bold);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SearchableMarkdownBody(
                data: stripHtmlTags(table.markdown),
                highlightQuery: highlightQuery,
                styleSheet: MarkdownStyleSheet(
                  p: tableStyle,
                  tableHead: headStyle,
                  tableBody: tableStyle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context, NrImageBlock image) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: fontSize - 1,
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (image.alt.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: fontSize,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${image.alt} — toque na imagem para ampliar',
                    style: captionStyle,
                  ),
                ),
              ],
            ),
          ),
        NrMarkdownImageBuilder(
          uri: Uri.parse(image.src),
          nrId: nrId,
          alt: image.alt,
        ),
      ],
    );
  }

  Widget _buildNote(BuildContext context, NrNoteBlock note) {
    final semantics = context.semanticColors;
    final noteStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: fontSize - 1,
      fontStyle: FontStyle.italic,
      color: semantics.onWarningContainer,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: HighlightedText(
        text: stripInlineMarkup(note.text),
        highlight: highlightQuery,
        style: noteStyle,
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, NrParagraphBlock paragraph) {
    final text = paragraph.text;
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final baseStyle = _bodyStyle(context);

    if (looksLikeMarkdownParagraph(text)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SearchableMarkdownBody(
          data: text,
          highlightQuery: highlightQuery,
          styleSheet: MarkdownStyleSheet(
            p: baseStyle,
            h1: baseStyle.copyWith(
              fontSize: fontSize + 4,
              fontWeight: FontWeight.bold,
            ),
            h2: baseStyle.copyWith(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
            ),
            strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
            em: baseStyle.copyWith(fontStyle: FontStyle.italic),
            listBullet: baseStyle,
          ),
          nrId: nrId,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: HighlightedText(
        text: stripInlineMarkup(text),
        highlight: highlightQuery,
        style: baseStyle,
      ),
    );
  }
}
