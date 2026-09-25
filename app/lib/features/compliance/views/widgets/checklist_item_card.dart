/// Card de um item do checklist.
///
/// Mostra título, gravidade da autuação (NR-28), explicação e ações.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/compliance_item.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../features/reader/utils/reader_navigation.dart';
import '../../compliance_copy.dart';
import '../../controllers/checklist_controller.dart';

class ChecklistItemCard extends StatelessWidget {
  final ComplianceItem item;

  const ChecklistItemCard({
    required this.item,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChecklistController>();
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.nrId.toUpperCase()} · item ${item.itemNumber}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.titulo,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                if (item.infracao) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _SeverityChip(item: item),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              item.explicacao,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
            ),

            if (item.infracao &&
                item.codigoInfracao != null &&
                item.codigoInfracao!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '${ComplianceCopy.nr28CodePrefix} · ${item.codigoInfracao}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: muted,
                      height: 1.35,
                    ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: muted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Responsável: ${item.responsavel}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Row(
                    children: [
                      Checkbox(
                        value: controller.isItemChecked(item),
                        onChanged: (_) => controller.toggleItemChecked(item),
                      ),
                      Text(
                        controller.isItemChecked(item)
                            ? 'Verificado'
                            : 'Verificar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: controller.isItemChecked(item)
                                  ? FontWeight.bold
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Compartilhar item',
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: item.toShareText()),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openInReader(item),
                      child: const Text('Ver na norma'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openInReader(ComplianceItem item) {
    ReaderNavigation.open(
      nrId: item.nrId,
      initialAnchor: item.readerAnchorId,
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.item});

  final ComplianceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.semanticColors;
    final colorScheme = theme.colorScheme;
    final style = _styleForGradacao(item.gradacao, colorScheme, semantics);

    final severityWord = item.gradacaoSeverityWord ?? 'Autuação';
    final code = item.gradacao;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              severityWord,
              style: theme.textTheme.labelMedium?.copyWith(
                color: style.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (code != null && code.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '|',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: style.foreground.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Semantics(
                label: item.gradacaoCodeSemanticsLabel ?? code,
                child: Text(
                  code,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            if (item.tipoShortLabel != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Tooltip(
                  message: item.tipoLabel ?? item.tipoShortLabel!,
                  child: Text(
                    item.tipoShortLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: style.foreground.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _SeverityChipStyle _styleForGradacao(
    String? gradacao,
    ColorScheme colorScheme,
    AppSemanticColors semantics,
  ) {
    return switch (gradacao) {
      'I1' => _SeverityChipStyle(
        background: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        foreground: colorScheme.onSurfaceVariant,
        border: colorScheme.outline.withValues(alpha: 0.35),
      ),
      'I2' => _SeverityChipStyle(
        background: semantics.infoContainer.withValues(alpha: 0.85),
        foreground: semantics.onInfoContainer,
        border: semantics.info.withValues(alpha: 0.35),
      ),
      'I3' => _SeverityChipStyle(
        background: semantics.warningContainer,
        foreground: semantics.onWarningContainer,
        border: semantics.warning.withValues(alpha: 0.45),
      ),
      'I4' => _SeverityChipStyle(
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
        border: colorScheme.error.withValues(alpha: 0.4),
      ),
      _ => _SeverityChipStyle(
        background: colorScheme.surfaceContainerHigh,
        foreground: colorScheme.onSurfaceVariant,
        border: colorScheme.outline.withValues(alpha: 0.35),
      ),
    };
  }
}

class _SeverityChipStyle {
  const _SeverityChipStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}
