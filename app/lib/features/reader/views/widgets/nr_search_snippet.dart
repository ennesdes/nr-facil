import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';

/// Snippet de texto com termo de busca destacado (case-insensitive).
class NrSearchSnippet extends StatelessWidget {
  final String text;
  final String searchQuery;
  final TextStyle? style;
  final int maxLines;

  const NrSearchSnippet({
    required this.text,
    required this.searchQuery,
    this.style,
    this.maxLines = 3,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodySmall;
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final normalizedText = text.toLowerCase();
    final index = normalizedText.indexOf(normalizedQuery);

    if (normalizedQuery.isEmpty || index == -1) {
      final snippet = text.length > 120 ? '${text.substring(0, 120)}...' : text;
      return Text(
        snippet,
        style: baseStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final start = (index - 60).clamp(0, text.length);
    final end = (index + normalizedQuery.length + 60).clamp(0, text.length);
    var snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';

    final matchInSnippet = snippet.toLowerCase().indexOf(normalizedQuery);
    if (matchInSnippet == -1) {
      return Text(snippet, style: baseStyle, maxLines: maxLines);
    }

    final matchedText = snippet.substring(
      matchInSnippet,
      matchInSnippet + normalizedQuery.length,
    );

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: snippet.substring(0, matchInSnippet)),
          TextSpan(
            text: matchedText,
            style: baseStyle?.copyWith(
              fontWeight: FontWeight.bold,
              backgroundColor: context.searchHighlightColor,
            ),
          ),
          TextSpan(
            text: snippet.substring(matchInSnippet + matchedText.length),
          ),
        ],
      ),
    );
  }
}
