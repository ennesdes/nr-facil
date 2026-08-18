/// Modelo para um chunk de búsqueda (search_index.json).
///
/// Schema: `{"id": "chunk-N", "text": "...", "heading": "Nome da Seção", "char_offset": N}`
/// Usado para busca full-text e navegação para seção específica.
library;

class SearchChunk {
  final String id;
  final String text;
  final String heading;
  final int charOffset;

  SearchChunk({
    required this.id,
    required this.text,
    required this.heading,
    required this.charOffset,
  });

  factory SearchChunk.fromMap(Map<String, dynamic> map) {
    // Conversão defensiva — sem lançar exceção em cache corrompido
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

    return SearchChunk(
      id: stringValue(map['id']),
      text: stringValue(map['text']),
      heading: stringValue(map['heading']),
      charOffset: intValue(map['char_offset']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'heading': heading,
      'char_offset': charOffset,
    };
  }
}

