import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/models/nr_search_hit.dart';
import 'package:nrfacil/features/reader/utils/markdown_utils.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Busca abrangente em structure.json — uma entrada por ocorrência do termo.
List<NrSearchHit> searchInNrDocument(NrStructure structure, String query) {
  final normalized = normalizeForSearch(query);
  if (normalized.isEmpty) return [];

  final results = <NrSearchHit>[];
  final queryLength = normalized.length;

  void addOccurrenceHits({
    required String sectionId,
    required int blockIndex,
    required String label,
    required String text,
  }) {
    final clean = stripInlineMarkup(text);
    if (clean.isEmpty) return;

    for (final offset in findOccurrenceOffsets(clean, query)) {
      results.add(
        NrSearchHit(
          sectionId: sectionId,
          blockIndex: blockIndex,
          matchStart: offset,
          label: label,
          snippet: searchSnippetAt(
            clean,
            offset: offset,
            queryLength: queryLength,
          ),
        ),
      );
    }
  }

  addOccurrenceHits(
    sectionId: 'meta',
    blockIndex: -1,
    label: 'Título da NR',
    text: structure.title,
  );

  for (var i = 0; i < structure.preamble.blocks.length; i++) {
    addOccurrenceHits(
      sectionId: 'preamble',
      blockIndex: i,
      label: 'Publicação e histórico',
      text: nrBlockPlainText(structure.preamble.blocks[i]),
    );
  }

  for (final section in structure.sections) {
    final titleText = section.displayTitle;
    addOccurrenceHits(
      sectionId: section.id,
      blockIndex: -1,
      label: titleText,
      text: titleText,
    );

    for (var i = 0; i < section.blocks.length; i++) {
      addOccurrenceHits(
        sectionId: section.id,
        blockIndex: i,
        label: titleText,
        text: nrBlockPlainText(section.blocks[i]),
      );
    }
  }

  return results;
}

/// Fallback: busca no Markdown bruto quando structure.json não está disponível.
List<NrSearchHit> searchInMarkdownContent(
  String markdown,
  NrStructure? structure,
  String query,
) {
  final normalized = normalizeForSearch(query);
  if (normalized.isEmpty) return [];

  final results = <NrSearchHit>[];
  final queryLength = normalized.length;

  for (final section in splitMarkdownBySections(markdown)) {
    final text = stripInlineMarkup(section.markdownContent);
    if (text.isEmpty) continue;

    var sectionId = 'content';
    var label = 'Conteúdo';

    if (section.headingText != null) {
      label = stripInlineMarkup(section.headingText!);
      if (structure != null) {
        final headingNorm = normalizeForSearch(section.headingText!);
        for (final sec in structure.sections) {
          final titleNorm = normalizeForSearch(sec.displayTitle);
          final numberNorm = normalizeForSearch(sec.number);
          if (titleNorm.contains(headingNorm) ||
              headingNorm.contains(titleNorm) ||
              headingNorm.contains(numberNorm)) {
            sectionId = sec.id;
            label = sec.displayTitle;
            break;
          }
        }
      }
    }

    for (final offset in findOccurrenceOffsets(text, query)) {
      results.add(
        NrSearchHit(
          sectionId: sectionId,
          blockIndex: 0,
          matchStart: offset,
          label: label,
          snippet: searchSnippetAt(
            text,
            offset: offset,
            queryLength: queryLength,
          ),
        ),
      );
    }
  }

  return results;
}

String nrBlockPlainText(NrBlock block) {
  return switch (block) {
    NrItemBlock item => '${item.number} ${item.text}',
    NrListBlock list =>
      list.items.map((i) => '${i.label}) ${i.text}').join(' '),
    NrTableBlock table => table.markdown,
    NrImageBlock image => image.alt,
    NrNoteBlock note => note.text,
    NrParagraphBlock paragraph => paragraph.text,
  };
}
