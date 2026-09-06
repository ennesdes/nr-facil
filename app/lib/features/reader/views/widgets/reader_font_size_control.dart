import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Controle A− / valor / A+ para tamanho de fonte no menu do leitor.
///
/// Observa [fontSize] reativamente para atualizar o valor exibido enquanto o
/// menu popup permanece aberto.
class ReaderFontSizeControl extends StatelessWidget {
  final Rx<double> fontSize;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const ReaderFontSizeControl({
    required this.fontSize,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final size = fontSize.value;
      final canDecrease = size > kReaderFontSizes.first;
      final canIncrease = size < kReaderFontSizes.last;
      final colorScheme = Theme.of(context).colorScheme;
      final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          );

      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tamanho do texto', style: labelStyle),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    _StepButton(
                      label: 'A−',
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      enabled: canDecrease,
                      onPressed: onDecrease,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.md),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          size.toInt().toString(),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant,
                    ),
                    _StepButton(
                      label: 'A+',
                      labelStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      enabled: canIncrease,
                      onPressed: onIncrease,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(AppRadius.md),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final bool enabled;
  final VoidCallback onPressed;
  final BorderRadius borderRadius;

  const _StepButton({
    required this.label,
    required this.labelStyle,
    required this.enabled,
    required this.onPressed,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.38);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: borderRadius,
        child: SizedBox(
          width: 52,
          height: 48,
          child: Center(
            child: Text(
              label,
              style: labelStyle.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
