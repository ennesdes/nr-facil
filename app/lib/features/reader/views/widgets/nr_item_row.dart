import 'package:flutter/material.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';

/// Linha de item numerado (6.1.1, 6.1.1.1, etc.).
class NrItemRow extends StatelessWidget {
  final String number;
  final int depth;
  final String text;
  final double fontSize;
  final String? highlightQuery;

  const NrItemRow({
    required this.number,
    required this.depth,
    required this.text,
    required this.fontSize,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indent = (depth - 1) * 12.0;

    return Padding(
      padding: EdgeInsets.only(
        left: indent,
        top: 8,
        bottom: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HighlightedText(
              text: text,
              highlight: highlightQuery,
              selectable: true,
              style: TextStyle(
                fontSize: fontSize,
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
