/// Utilitários de texto para o leitor estruturado.
library;

/// Remove apenas tags HTML (preserva Markdown como **negrito** e tabelas).
String stripHtmlTags(String text) {
  return text.replaceAll(RegExp(r'<[^>]+>'), '');
}

/// Segmento de texto inline com negrito Markdown opcional.
class InlineMarkdownSegment {
  const InlineMarkdownSegment(this.text, {this.isBold = false});

  final String text;
  final bool isBold;
}

/// Interpreta `**negrito**`, `_(nota)_` e tags HTML como no leitor.
List<InlineMarkdownSegment> parseInlineMarkdownSegments(String raw) {
  final segments = <InlineMarkdownSegment>[];
  final plainBuffer = StringBuffer();

  void flushPlain() {
    if (plainBuffer.isEmpty) return;
    segments.add(InlineMarkdownSegment(plainBuffer.toString()));
    plainBuffer.clear();
  }

  var index = 0;
  while (index < raw.length) {
    if (raw.startsWith('**', index)) {
      final end = raw.indexOf('**', index + 2);
      if (end != -1) {
        flushPlain();
        segments.add(
          InlineMarkdownSegment(raw.substring(index + 2, end), isBold: true),
        );
        index = end + 2;
        continue;
      }
    }

    final htmlMatch = RegExp(r'<[^>]+>').matchAsPrefix(raw, index);
    if (htmlMatch != null) {
      index = htmlMatch.end;
      continue;
    }

    if (raw.startsWith('_(', index)) {
      final end = raw.indexOf(')_', index + 2);
      if (end != -1) {
        plainBuffer.write(raw.substring(index + 2, end));
        index = end + 2;
        continue;
      }
    }

    plainBuffer.write(raw[index]);
    index += 1;
  }

  flushPlain();
  return segments;
}

/// Remove marcação Markdown/HTML inline para exibição.
String stripInlineMarkup(String text) {
  var result = text;
  result = result.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => m.group(1) ?? '',
  );
  result = result.replaceAllMapped(RegExp(r'<[^>]+>'), (_) => '');
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
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'Å': 'A',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ø': 'O',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ç': 'C',
    'Ñ': 'N',
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

/// Trecho do Markdown original centrado em uma ocorrência de busca.
String extractMarkdownSnippet(
  String raw, {
  required String query,
  int context = 60,
  int maxLength = 200,
}) {
  final clean = stripInlineMarkup(raw);
  if (clean.isEmpty) return '';

  final normalizedQuery = normalizeForSearch(query);
  if (normalizedQuery.isEmpty) {
    return clean.length > maxLength
        ? '${clean.substring(0, maxLength)}...'
        : clean;
  }

  final normalizedText = normalizeForSearch(clean);
  final index = normalizedText.indexOf(normalizedQuery);
  if (index == -1) {
    return clean.length > maxLength
        ? '${clean.substring(0, maxLength)}...'
        : clean;
  }

  final cleanStart = (index - context).clamp(0, clean.length);
  final cleanEnd = (index + normalizedQuery.length + context).clamp(
    0,
    clean.length,
  );

  var snippet = rawMarkdownForCleanRange(raw, cleanStart, cleanEnd);
  if (cleanStart > 0) snippet = '...$snippet';
  if (cleanEnd < clean.length) snippet = '$snippet...';
  if (snippet.length > maxLength) {
    snippet = '${snippet.substring(0, maxLength)}...';
  }
  return snippet;
}

String rawMarkdownForCleanRange(String raw, int cleanStart, int cleanEnd) {
  if (cleanStart >= cleanEnd) return '';

  final buffer = StringBuffer();
  var cleanIndex = 0;
  var index = 0;

  while (index < raw.length && cleanIndex < cleanEnd) {
    if (raw.startsWith('**', index)) {
      final end = raw.indexOf('**', index + 2);
      if (end != -1) {
        final content = raw.substring(index + 2, end);
        final segmentStart = cleanIndex;
        cleanIndex += content.length;
        if (segmentStart < cleanEnd && cleanIndex > cleanStart) {
          buffer.write(raw.substring(index, end + 2));
        }
        index = end + 2;
        continue;
      }
    }

    final htmlMatch = RegExp(r'<[^>]+>').matchAsPrefix(raw, index);
    if (htmlMatch != null) {
      index = htmlMatch.end;
      continue;
    }

    if (raw.startsWith('_(', index)) {
      final end = raw.indexOf(')_', index + 2);
      if (end != -1) {
        final content = raw.substring(index + 2, end);
        final segmentStart = cleanIndex;
        cleanIndex += content.length;
        if (segmentStart < cleanEnd && cleanIndex > cleanStart) {
          buffer.write(raw.substring(index, end + 2));
        }
        index = end + 2;
        continue;
      }
    }

    if (cleanIndex >= cleanStart && cleanIndex < cleanEnd) {
      buffer.write(raw[index]);
    }
    cleanIndex += 1;
    index += 1;
  }

  return buffer.toString();
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
