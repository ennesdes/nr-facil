/// Utilitários de texto para o leitor estruturado.
library;

/// Remove marcação Markdown/HTML inline para exibição.
String stripInlineMarkup(String text) {
  var result = text;
  result = result.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(
    RegExp(r'<[^>]+>'),
    (_) => '',
  );
  result = result.replaceAllMapped(
    RegExp(r'_\(([^)]+)\)_'),
    (m) => m.group(1) ?? '',
  );
  return result.trim();
}

/// Indica se o texto parece conter Markdown estrutural (não só negrito inline).
bool looksLikeMarkdownParagraph(String text) {
  return RegExp(r'(^|\n)#+\s').hasMatch(text) ||
      RegExp(r'(^|\n)\s*[-*]\s').hasMatch(text) ||
      RegExp(r'(^|\n)\|').hasMatch(text);
}

/// Normaliza texto para busca: remove markup, diacríticos e caixa.
String normalizeForSearch(String text) {
  final clean = stripInlineMarkup(text).toLowerCase();
  return _removeDiacritics(clean);
}

String _removeDiacritics(String text) {
  const map = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
    'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
    'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
    'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
    'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O', 'Ø': 'O',
    'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
    'Ç': 'C', 'Ñ': 'N',
  };

  final buffer = StringBuffer();
  for (final char in text.runes) {
    final s = String.fromCharCode(char);
    buffer.write(map[s] ?? s);
  }
  return buffer.toString();
}

/// Retorna os offsets de cada ocorrência de [query] em [text] (texto já limpo).
List<int> findOccurrenceOffsets(String text, String query) {
  final normalizedQuery = normalizeForSearch(query);
  if (normalizedQuery.isEmpty) return [];

  final normalizedText = normalizeForSearch(text);
  final offsets = <int>[];
  var start = 0;

  while (true) {
    final index = normalizedText.indexOf(normalizedQuery, start);
    if (index == -1) break;
    offsets.add(index);
    start = index + normalizedQuery.length;
  }

  return offsets;
}

/// Trecho de texto centrado em uma ocorrência para exibição.
String searchSnippetAt(
  String text, {
  required int offset,
  required int queryLength,
  int context = 60,
}) {
  final clean = stripInlineMarkup(text);
  if (clean.isEmpty) return '';

  final start = (offset - context).clamp(0, clean.length);
  final end = (offset + queryLength + context).clamp(0, clean.length);
  var snippet = clean.substring(start, end);
  if (start > 0) snippet = '...$snippet';
  if (end < clean.length) snippet = '$snippet...';
  if (snippet.length > 200) {
    snippet = '${snippet.substring(0, 200)}...';
  }
  return snippet;
}
