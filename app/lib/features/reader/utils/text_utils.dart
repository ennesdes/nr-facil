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
