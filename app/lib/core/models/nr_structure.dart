/// Modelo para structure.json — leitor estruturado de NRs.
library;

/// Estrutura completa de uma NR para exibição nativa.
class NrStructure {
  final String title;
  final NrPreamble preamble;
  final List<NrSection> sections;

  NrStructure({
    required this.title,
    required this.preamble,
    required this.sections,
  });

  factory NrStructure.fromMap(Map<String, dynamic> map) {
    final preambleMap = map['preamble'] as Map<String, dynamic>? ?? {};
    final sectionsList = (map['sections'] as List<dynamic>?)
            ?.map((e) => NrSection.fromMap(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList() ??
        [];

    return NrStructure(
      title: map['title'] as String? ?? '',
      preamble: NrPreamble.fromMap(preambleMap),
      sections: sectionsList,
    );
  }

  bool get isEmpty => sections.isEmpty && preamble.blocks.isEmpty;
}

/// Preâmbulo colapsável (publicação, alterações, sumário).
class NrPreamble {
  final List<NrBlock> blocks;

  NrPreamble({required this.blocks});

  factory NrPreamble.fromMap(Map<String, dynamic> map) {
    final blocksList = (map['blocks'] as List<dynamic>?)
            ?.map((e) => NrBlock.fromMap(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList() ??
        [];
    return NrPreamble(blocks: blocksList);
  }
}

/// Seção normativa (6.1, Anexo I, etc.).
class NrSection {
  final String id;
  final String number;
  final String title;
  final List<NrBlock> blocks;

  NrSection({
    required this.id,
    required this.number,
    required this.title,
    required this.blocks,
  });

  factory NrSection.fromMap(Map<String, dynamic> map) {
    final blocksList = (map['blocks'] as List<dynamic>?)
            ?.map((e) => NrBlock.fromMap(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList() ??
        [];

    return NrSection(
      id: map['id'] as String? ?? '',
      number: map['number'] as String? ?? '',
      title: map['title'] as String? ?? '',
      blocks: blocksList,
    );
  }

  /// Título de exibição limpo: "6.1 Objetivo"
  String get displayTitle {
    if (number.isEmpty) return title;
    if (title.isEmpty) return number;
    return '$number $title';
  }
}

/// Bloco de conteúdo tipado dentro de seção ou preâmbulo.
sealed class NrBlock {
  const NrBlock();

  factory NrBlock.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'paragraph';
    return switch (type) {
      'item' => NrItemBlock.fromMap(map),
      'list' => NrListBlock.fromMap(map),
      'table' => NrTableBlock.fromMap(map),
      'image' => NrImageBlock.fromMap(map),
      'note' => NrNoteBlock.fromMap(map),
      _ => NrParagraphBlock.fromMap(map),
    };
  }
}

class NrItemBlock extends NrBlock {
  final String number;
  final int depth;
  final String text;

  const NrItemBlock({
    required this.number,
    required this.depth,
    required this.text,
  });

  factory NrItemBlock.fromMap(Map<String, dynamic> map) {
    return NrItemBlock(
      number: map['number'] as String? ?? '',
      depth: (map['depth'] as num?)?.toInt() ?? 1,
      text: map['text'] as String? ?? '',
    );
  }
}

class NrListItem {
  final String label;
  final String text;

  const NrListItem({required this.label, required this.text});

  factory NrListItem.fromMap(Map<String, dynamic> map) {
    return NrListItem(
      label: map['label'] as String? ?? '',
      text: map['text'] as String? ?? '',
    );
  }
}

class NrListBlock extends NrBlock {
  final List<NrListItem> items;

  const NrListBlock({required this.items});

  factory NrListBlock.fromMap(Map<String, dynamic> map) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((e) => NrListItem.fromMap(
                e is Map<String, dynamic> ? e : <String, dynamic>{}))
            .toList() ??
        [];
    return NrListBlock(items: itemsList);
  }
}

class NrTableBlock extends NrBlock {
  final String markdown;

  const NrTableBlock({required this.markdown});

  factory NrTableBlock.fromMap(Map<String, dynamic> map) {
    return NrTableBlock(markdown: map['markdown'] as String? ?? '');
  }
}

class NrImageBlock extends NrBlock {
  final String alt;
  final String src;

  const NrImageBlock({required this.alt, required this.src});

  factory NrImageBlock.fromMap(Map<String, dynamic> map) {
    return NrImageBlock(
      alt: map['alt'] as String? ?? '',
      src: map['src'] as String? ?? '',
    );
  }
}

class NrNoteBlock extends NrBlock {
  final String text;

  const NrNoteBlock({required this.text});

  factory NrNoteBlock.fromMap(Map<String, dynamic> map) {
    return NrNoteBlock(text: map['text'] as String? ?? '');
  }
}

class NrParagraphBlock extends NrBlock {
  final String text;

  const NrParagraphBlock({required this.text});

  factory NrParagraphBlock.fromMap(Map<String, dynamic> map) {
    return NrParagraphBlock(text: map['text'] as String? ?? '');
  }
}

class NrStructureParseException implements Exception {
  final String message;
  NrStructureParseException(this.message);

  @override
  String toString() => 'NrStructureParseException: $message';
}
