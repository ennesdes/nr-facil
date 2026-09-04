import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_item_actions.dart';

/// Linha de item numerado (6.1.1, 6.1.1.1, etc.) — número em linha própria.
class NrItemRow extends StatelessWidget {
  final String nrId;
  final String number;
  final int depth;
  final String text;
  final double fontSize;
  final String? highlightQuery;

  const NrItemRow({
    required this.nrId,
    required this.number,
    required this.depth,
    required this.text,
    required this.fontSize,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final indent = (depth - 1) * 14.0;

    final numberStyle = readerItemNumberStyle(context, fontSize);
    final bodyStyle = readerBodyStyle(context, fontSize);

    return Padding(
      padding: EdgeInsets.only(
        left: indent,
        top: depth <= 2 ? AppSpacing.md : AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onLongPress: () => ReaderItemActions.showMenu(
                context: context,
                nrId: nrId,
                itemNumber: number,
                text: text,
              ),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(number, style: numberStyle),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          HighlightedText(
            text: text,
            highlight: highlightQuery,
            selectable: true,
            style: bodyStyle,
          ),
        ],
      ),
    );
  }
}
