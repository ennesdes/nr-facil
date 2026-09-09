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
  final bool preserveBold;

  const HighlightedText({
    required this.text,
    this.highlight,
    this.style,
    this.maxLines,
    this.selectable = true,
    this.preserveBold = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final query = highlight?.trim();
    final segments = preserveBold
        ? parseInlineMarkdownSegments(text)
        : [InlineMarkdownSegment(stripInlineMarkup(text))];

    if (query == null || query.isEmpty) {
      return _buildRichText(
        context,
        _segmentsToSpans(segments, baseStyle),
        selectable: selectable,
      );
    }

    final normalizedQuery = normalizeForSearch(query);
    if (normalizedQuery.isEmpty) {
      return _buildRichText(
        context,
        _segmentsToSpans(segments, baseStyle),
        selectable: selectable,
      );
    }

    final spans = <TextSpan>[];
    for (final segment in segments) {
      spans.addAll(
        _highlightSegment(context, segment, baseStyle, normalizedQuery),
      );
    }

    return _buildRichText(context, spans, selectable: selectable);
  }

  List<TextSpan> _segmentsToSpans(
    List<InlineMarkdownSegment> segments,
    TextStyle baseStyle,
  ) {
    return segments
        .map(
          (segment) => TextSpan(
            text: segment.text,
            style: _segmentStyle(baseStyle, segment.isBold),
          ),
        )
        .toList();
  }

  TextStyle _segmentStyle(TextStyle baseStyle, bool isBold) {
    if (!isBold) return baseStyle;
    return baseStyle.copyWith(fontWeight: FontWeight.bold);
  }

  List<TextSpan> _highlightSegment(
    BuildContext context,
    InlineMarkdownSegment segment,
    TextStyle baseStyle,
    String normalizedQuery,
  ) {
    final clean = segment.text;
    if (clean.isEmpty) return const [];

    final segmentStyle = _segmentStyle(baseStyle, segment.isBold);
    final normalizedText = normalizeForSearch(clean);
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final index = normalizedText.indexOf(normalizedQuery, start);
      if (index == -1) {
        if (start < clean.length) {
          spans.add(
            TextSpan(text: clean.substring(start), style: segmentStyle),
          );
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: clean.substring(start, index), style: segmentStyle),
        );
      }

      final matched = clean.substring(index, index + normalizedQuery.length);
      spans.add(
        TextSpan(
          text: matched,
          style: segmentStyle.copyWith(
            backgroundColor: context.searchHighlightColor,
            color: context.onSearchHighlightColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = index + normalizedQuery.length;
    }

    return spans;
  }

  Widget _buildRichText(
    BuildContext context,
    List<TextSpan> spans, {
    required bool selectable,
  }) {
    final rich = TextSpan(children: spans);
    if (selectable) {
      return SelectableText.rich(rich, maxLines: maxLines);
    }

    return Text.rich(
      rich,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
}
