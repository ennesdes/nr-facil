/// Modelo para índice de navegação de uma NR (index.json).
///
/// Schema: `{"headings": [{"level": int, "text": string, "id": string}]}`
/// Usado para navegação lateral no leitor.
library;

class NrIndex {
  final List<Heading> headings;

  NrIndex({
    required this.headings,
  });

  factory NrIndex.fromMap(Map<String, dynamic> map) {
    try {
      final headingsList = (map['headings'] as List<dynamic>?)
          ?.map((e) => Heading.fromMap(
              e is Map<String, dynamic> ? e : <String, dynamic>{}))
          .toList() ?? [];

      return NrIndex(
        headings: headingsList,
      );
    } catch (e) {
      // Index corrompido — retornar vazio
      throw NrIndexParseException('Falha ao parsear index.json: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'headings': headings.map((e) => e.toMap()).toList(),
    };
  }
}

/// Entrada individual de um heading no índice.
class Heading {
  final int level; // 1, 2, 3, etc
  final String text; // ex: "6.1 Objetivo"
  final String id; // ex: "heading-6-1" (âncora para navegação)

  Heading({
    required this.level,
    required this.text,
    required this.id,
  });

  factory Heading.fromMap(Map<String, dynamic> map) {
    return Heading(
      level: (map['level'] as num?)?.toInt() ?? 1,
      text: map['text'] as String? ?? '',
      id: map['id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'text': text,
      'id': id,
    };
  }
}

class NrIndexParseException implements Exception {
  final String message;
  NrIndexParseException(this.message);

  @override
  String toString() => 'NrIndexParseException: $message';
}
