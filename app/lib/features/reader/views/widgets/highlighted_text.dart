import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';

import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Texto com o termo de busca destacado.
class HighlightedText extends StatelessWidget {
  final String text;
  final String? highlight;
  final TextStyle? style;
  final int? maxLines;
  final bool selectable;

  const HighlightedText({
    required this.text,
    this.highlight,
    this.style,
    this.maxLines,
    this.selectable = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final clean = stripInlineMarkup(text);
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final query = highlight?.trim();

    if (query == null || query.isEmpty) {
      if (selectable) {
        return SelectableText(clean, style: baseStyle, maxLines: maxLines);
      }
      return Text(clean, style: baseStyle, maxLines: maxLines);
    }

    final normalizedQuery = normalizeForSearch(query);
    if (normalizedQuery.isEmpty) {
      if (selectable) {
        return SelectableText(clean, style: baseStyle, maxLines: maxLines);
      }
      return Text(clean, style: baseStyle, maxLines: maxLines);
    }

    final normalizedText = normalizeForSearch(clean);
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = normalizedText.indexOf(normalizedQuery, start);
      if (index == -1) {
        if (start < clean.length) {
          spans.add(TextSpan(text: clean.substring(start), style: baseStyle));
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: clean.substring(start, index), style: baseStyle),
        );
      }

      final matched = clean.substring(index, index + normalizedQuery.length);
      spans.add(
        TextSpan(
          text: matched,
          style: baseStyle.copyWith(
            backgroundColor: context.searchHighlightColor,
            color: context.onSearchHighlightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = index + normalizedQuery.length;
    }

    final rich = TextSpan(children: spans);
    if (selectable) {
      return SelectableText.rich(
        rich,
        maxLines: maxLines,
      );
    }

    return Text.rich(
      rich,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
