/// Modelo para um chunk de busca (search_index.json).
///
/// Schema base: `{"id", "text", "heading", "char_offset"}`
/// Tabela em PNG: `kind: image_png` (ou legado `page_table`), `page`, `image_src`
library;

class SearchChunk {
  final String id;
  final String text;
  final String heading;
  final int charOffset;

  /// `text` (padrão) ou `image_png` / `page_table` (tabela virou imagem).
  final String kind;

  /// Página 1-based do PDF (chunks de imagem indexada).
  final int? pageNumber;

  /// Caminho relativo no pacote da NR (ex.: ../assets/pages/page-005-table-full.png).
  final String? imageSrc;

  SearchChunk({
    required this.id,
    required this.text,
    required this.heading,
    required this.charOffset,
    this.kind = 'text',
    this.pageNumber,
    this.imageSrc,
  });

  /// Resultado aponta para bloco imagem no leitor (busca usa texto MD, não pixel).
  bool get isImageSearchResult =>
      kind == 'image_png' || kind == 'page_table';

  factory SearchChunk.fromMap(Map<String, dynamic> map) {
    String stringValue(dynamic value) {
      if (value is String) return value;
      if (value == null) return '';
      return value.toString();
    }

    int intValue(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return 0;
    }

    int? optionalInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    final kind = stringValue(map['kind']);
    final imageSrcRaw = stringValue(map['image_src']);

    return SearchChunk(
      id: stringValue(map['id']),
      text: stringValue(map['text']),
      heading: stringValue(map['heading']),
      charOffset: intValue(map['char_offset']),
      kind: kind.isEmpty ? 'text' : kind,
      pageNumber: optionalInt(map['page']),
      imageSrc: imageSrcRaw.isEmpty ? null : imageSrcRaw,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'heading': heading,
      'char_offset': charOffset,
      if (kind != 'text') 'kind': kind,
      if (pageNumber != null) 'page': pageNumber,
      if (imageSrc != null) 'image_src': imageSrc,
    };
  }
}
