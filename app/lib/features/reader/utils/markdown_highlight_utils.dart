import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Delimitadores internos para sintaxe customizada de destaque no Markdown.
const searchHighlightOpen = '⟦';
const searchHighlightClose = '⟧';

/// Injeta marcadores de destaque no Markdown sem alterar a estrutura.
String injectMarkdownHighlights(String markdown, String? query) {
  final trimmed = query?.trim();
  if (trimmed == null || trimmed.isEmpty) return markdown;

  final normalizedQuery = normalizeForSearch(trimmed);
  if (normalizedQuery.isEmpty) return markdown;

  return markdown
      .split('\n')
      .map((line) => _highlightMarkdownLine(line, normalizedQuery))
      .join('\n');
}

String _highlightMarkdownLine(String line, String normalizedQuery) {
  if (line.trim().isEmpty) return line;

  if (line.contains('|')) {
    return _highlightTableLine(line, normalizedQuery);
  }

  final headingMatch = RegExp(r'^(#+\s+)').firstMatch(line);
  if (headingMatch != null) {
    final prefix = headingMatch.group(1)!;
    final rest = line.substring(headingMatch.end);
    return '$prefix${_highlightInlineMarkdown(rest, normalizedQuery)}';
  }

  final listMatch = RegExp(r'^(\s*(?:[-*+]|\w+\))\s+)').firstMatch(line);
  if (listMatch != null) {
    final prefix = listMatch.group(1)!;
    final rest = line.substring(listMatch.end);
    return '$prefix${_highlightInlineMarkdown(rest, normalizedQuery)}';
  }

  return _highlightInlineMarkdown(line, normalizedQuery);
}

String _highlightTableLine(String line, String normalizedQuery) {
  final parts = line.split('|');
  return parts
      .map((cell) => _highlightInlineMarkdown(cell, normalizedQuery))
      .join('|');
}

String _highlightInlineMarkdown(String content, String normalizedQuery) {
  final buffer = StringBuffer();
  for (final token in _tokenizeInline(content)) {
    buffer.write(
      token.isSyntax
          ? token.text
          : _highlightPlainText(token.text, normalizedQuery),
    );
  }
  return buffer.toString();
}

class _InlineToken {
  const _InlineToken(this.text, {required this.isSyntax});

  final String text;
  final bool isSyntax;
}

List<_InlineToken> _tokenizeInline(String content) {
  final tokens = <_InlineToken>[];
  var index = 0;

  while (index < content.length) {
    if (content[index] == '`') {
      final end = content.indexOf('`', index + 1);
      if (end != -1) {
        tokens.add(_InlineToken(content.substring(index, end + 1), isSyntax: true));
        index = end + 1;
        continue;
      }
    }

    if (content.startsWith('**', index)) {
      final end = content.indexOf('**', index + 2);
      if (end != -1) {
        tokens
          ..add(const _InlineToken('**', isSyntax: true))
          ..add(_InlineToken(content.substring(index + 2, end), isSyntax: false))
          ..add(const _InlineToken('**', isSyntax: true));
        index = end + 2;
        continue;
      }
    }

    if (content.startsWith('_(', index)) {
      final end = content.indexOf(')_', index + 2);
      if (end != -1) {
        tokens.add(
          _InlineToken(content.substring(index, end + 2), isSyntax: true),
        );
        index = end + 2;
        continue;
      }
    }

    final linkMatch = RegExp(r'\[([^\]]*)\]\(([^)]*)\)').matchAsPrefix(content, index);
    if (linkMatch != null) {
      tokens.add(_InlineToken(linkMatch.group(0)!, isSyntax: true));
      index = linkMatch.end;
      continue;
    }

    final htmlMatch = RegExp(r'<[^>]+>').matchAsPrefix(content, index);
    if (htmlMatch != null) {
      tokens.add(_InlineToken(htmlMatch.group(0)!, isSyntax: true));
      index = htmlMatch.end;
      continue;
    }

    final nextSpecial = _findNextSpecial(content, index);
    if (nextSpecial > index) {
      tokens.add(_InlineToken(content.substring(index, nextSpecial), isSyntax: false));
    }
    index = nextSpecial == index ? index + 1 : nextSpecial;
  }

  return tokens;
}

int _findNextSpecial(String content, int start) {
  const markers = ['`', '*', '[', '<', '_'];
  var next = content.length;
  for (final marker in markers) {
    final index = content.indexOf(marker, start);
    if (index != -1 && index < next) {
      next = index;
    }
  }
  return next;
}

String _highlightPlainText(String text, String normalizedQuery) {
  if (text.isEmpty) return text;

  final normalizedText = normalizeForSearch(text);
  final buffer = StringBuffer();
  var start = 0;

  while (true) {
    final index = normalizedText.indexOf(normalizedQuery, start);
    if (index == -1) {
      if (start < text.length) {
        buffer.write(text.substring(start));
      }
      break;
    }

    if (index > start) {
      buffer.write(text.substring(start, index));
    }

    final matched = text.substring(index, index + normalizedQuery.length);
    buffer
      ..write(searchHighlightOpen)
      ..write(matched)
      ..write(searchHighlightClose);
    start = index + normalizedQuery.length;
  }

  return buffer.toString();
}
