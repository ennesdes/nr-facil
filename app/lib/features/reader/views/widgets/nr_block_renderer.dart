import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:nrfacil/features/reader/views/widgets/markdown_image_builder.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_item_row.dart';

/// Renderiza um bloco tipado do structure.json.
class NrBlockRenderer extends StatelessWidget {
  final NrBlock block;
  final double fontSize;
  final bool isDarkMode;
  final String nrId;
  final String? highlightQuery;
  final bool isHighlighted;

  const NrBlockRenderer({
    required this.block,
    required this.fontSize,
    required this.isDarkMode,
    required this.nrId,
    this.highlightQuery,
    this.isHighlighted = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final child = switch (block) {
      NrItemBlock item => NrItemRow(
          number: item.number,
          depth: item.depth,
          text: stripInlineMarkup(item.text),
          fontSize: fontSize,
          isDarkMode: isDarkMode,
          highlightQuery: highlightQuery,
          isHighlighted: isHighlighted,
        ),
      NrListBlock list => _buildList(list),
      NrTableBlock table => _buildTable(table),
      NrImageBlock image => _buildImage(image),
      NrNoteBlock note => _buildNote(note),
      NrParagraphBlock paragraph => _buildParagraph(paragraph),
    };

    if (!isHighlighted) return child;

    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: child,
    );
  }

  Widget _buildList(NrListBlock list) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

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
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                Expanded(
                  child: HighlightedText(
                    text: stripInlineMarkup(item.text),
                    highlight: highlightQuery,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(NrTableBlock table) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MarkdownBody(
        data: table.markdown,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(fontSize: fontSize - 1, color: textColor),
          tableHead: TextStyle(
            fontSize: fontSize - 1,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          tableBody: TextStyle(fontSize: fontSize - 1, color: textColor),
        ),
      ),
    );
  }

  Widget _buildImage(NrImageBlock image) {
    return NrMarkdownImageBuilder(
      uri: Uri.parse(image.src),
      nrId: nrId,
      alt: image.alt,
    );
  }

  Widget _buildNote(NrNoteBlock note) {
    final textColor = isDarkMode ? Colors.amber[200] : Colors.amber[900];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: HighlightedText(
        text: stripInlineMarkup(note.text),
        highlight: highlightQuery,
        style: TextStyle(
          fontSize: fontSize - 1,
          fontStyle: FontStyle.italic,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(NrParagraphBlock paragraph) {
    final text = stripInlineMarkup(paragraph.text);
    if (text.isEmpty) return const SizedBox.shrink();

    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: HighlightedText(
        text: text,
        highlight: highlightQuery,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          height: 1.6,
        ),
      ),
    );
  }
}
