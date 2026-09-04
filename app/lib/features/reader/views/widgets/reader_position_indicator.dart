import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/utils/view_padding.dart';

/// Indicador flutuante de posição de leitura (item/seção + progresso).
class ReaderPositionIndicator extends StatelessWidget {
  final String? itemLabel;
  final int? progressPercent;
  final VoidCallback? onTap;

  const ReaderPositionIndicator({
    required this.itemLabel,
    required this.progressPercent,
    this.onTap,
    super.key,
  });

  static final _itemNumberPattern = RegExp(r'^\d+(\.\d+)+$');
  static final _sectionPattern = RegExp(r'^\d+(\.\d+)*\s+\S');

  @override
  Widget build(BuildContext context) {
    final label = itemLabel?.trim();
    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final percent = (progressPercent ?? 0).clamp(0, 100);
    final caption = _captionFor(label);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.sm + ViewPadding.bottomOf(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: colorScheme.surface.withValues(
              alpha: isDark ? 0.88 : 0.94,
            ),
            elevation: isDark ? 4 : 2,
            shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.35),
                ),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm + 2,
                    AppSpacing.sm,
                    AppSpacing.sm + 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProgressTrack(
                        value: percent / 100,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (caption != null)
                                  Text(
                                    caption,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: context.mutedTextColor,
                                          letterSpacing: 0.3,
                                        ),
                                  ),
                                Text(
                                  label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                        height: 1.2,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _PercentBadge(percent: percent),
                          Icon(
                            Icons.unfold_more,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _captionFor(String label) {
    if (_itemNumberPattern.hasMatch(label)) return 'Item';
    if (_sectionPattern.hasMatch(label)) return 'Seção';
    return null;
  }
}

class _ProgressTrack extends StatelessWidget {
  final double value;
  final ColorScheme colorScheme;

  const _ProgressTrack({
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * animatedValue;
            return SizedBox(
              height: 4,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const SizedBox(width: double.infinity, height: 4),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: SizedBox(width: width, height: 4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PercentBadge extends StatelessWidget {
  final int percent;

  const _PercentBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$percent%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}
