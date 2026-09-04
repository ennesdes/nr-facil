import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';

/// Chip discreto para retomar leitura de onde parou.
class ReaderContinueChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  const ReaderContinueChip({
    required this.label,
    required this.onTap,
    this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kReaderHorizontalPadding,
        AppSpacing.sm,
        kReaderHorizontalPadding,
        0,
      ),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Continuar de $label',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  InkWell(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
