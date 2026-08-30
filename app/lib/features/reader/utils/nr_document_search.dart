import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/models/nr_search_hit.dart';
import 'package:nrfacil/features/reader/utils/markdown_utils.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Busca abrangente em structure.json — título, seções e todos os blocos.
List<NrSearchHit> searchInNrDocument(NrStructure structure, String query) {
  final normalized = normalizeForSearch(query);
  if (normalized.isEmpty) return [];

  final results = <NrSearchHit>[];

  void addHit({
    required String sectionId,
    required int blockIndex,
    required String label,
    required String text,
  }) {
    final clean = stripInlineMarkup(text);
    if (clean.isEmpty) return;
    final snippet = clean.length > 200 ? '${clean.substring(0, 200)}...' : clean;
    results.add(
      NrSearchHit(
        sectionId: sectionId,
        blockIndex: blockIndex,
        label: label,
        snippet: snippet,
      ),
    );
  }

  bool matches(String text) =>
      normalizeForSearch(text).contains(normalized);

  if (matches(structure.title)) {
    addHit(
      sectionId: 'meta',
      blockIndex: -1,
      label: 'Título da NR',
      text: structure.title,
    );
  }

  for (var i = 0; i < structure.preamble.blocks.length; i++) {
    final text = nrBlockPlainText(structure.preamble.blocks[i]);
    if (matches(text)) {
      addHit(
        sectionId: 'preamble',
        blockIndex: i,
        label: 'Publicação e histórico',
        text: text,
      );
    }
  }

  for (final section in structure.sections) {
    final titleText = section.displayTitle;
    if (matches(titleText) ||
        matches(section.title) ||
        matches(section.number)) {
      addHit(
        sectionId: section.id,
        blockIndex: -1,
        label: titleText,
        text: titleText,
      );
    }

    for (var i = 0; i < section.blocks.length; i++) {
      final text = nrBlockPlainText(section.blocks[i]);
      if (matches(text)) {
        addHit(
          sectionId: section.id,
          blockIndex: i,
          label: titleText,
          text: text,
        );
      }
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

  for (final section in splitMarkdownBySections(markdown)) {
    final text = stripInlineMarkup(section.markdownContent);
    if (!normalizeForSearch(text).contains(normalized)) continue;

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

    final snippet =
        text.length > 200 ? '${text.substring(0, 200)}...' : text;
    results.add(
      NrSearchHit(
        sectionId: sectionId,
        blockIndex: 0,
        label: label,
        snippet: snippet,
      ),
    );
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
