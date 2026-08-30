import 'package:flutter/material.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';

/// Linha de item numerado (6.1.1, 6.1.1.1, etc.).
class NrItemRow extends StatelessWidget {
  final String number;
  final int depth;
  final String text;
  final double fontSize;
  final bool isDarkMode;
  final String? highlightQuery;

  const NrItemRow({
    required this.number,
    required this.depth,
    required this.text,
    required this.fontSize,
    required this.isDarkMode,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final badgeColor = isDarkMode
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    final badgeTextColor = isDarkMode
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.primary;

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
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              number,
              style: TextStyle(
                fontSize: fontSize - 2,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HighlightedText(
              text: text,
              highlight: highlightQuery,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
