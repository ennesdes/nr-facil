import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/features/updates/utils/update_item_display.dart';
import 'package:nrfacil/features/updates/views/widgets/update_table_comparison.dart';

/// Lista de itens granulares de uma atualização de NR.
class UpdateItemsList extends StatelessWidget {
  final List<UpdateItem> items;
  final String? nrId;
  final String? contentRef;
  final EdgeInsets padding;
  final double itemSpacing;

  const UpdateItemsList({
    required this.items,
    this.nrId,
    this.contentRef,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.itemSpacing = AppSpacing.md,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final display = UpdateItemDisplay.fromUpdateItem(item);
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < items.length - 1 ? itemSpacing : 0,
            ),
            child: _UpdateItemCard(
              item: item,
              display: display,
              nrId: nrId,
              contentRef: contentRef,
            ),
          );
        }),
      ),
    );
  }
}

class _UpdateItemCard extends StatelessWidget {
  final UpdateItem item;
  final UpdateItemDisplay display;
  final String? nrId;
  final String? contentRef;

  const _UpdateItemCard({
    required this.item,
    required this.display,
    this.nrId,
    this.contentRef,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.semanticColors;
    final style = _styleForType(context, display.tipo);
    final detailLabel = item.isTableChange ? 'Tabela alterada' : style.label;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: 18, color: style.color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item ${display.item}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      detailLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: style.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.isTableChange && item.tabela != null && nrId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            UpdateTableComparison(
              nrId: nrId!,
              contentRef: contentRef,
              tabela: item.tabela!,
            ),
          ] else if (display.isAlterado) ...[
            if (display.antes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _TextBlockSection(
                title: 'Antes',
                text: display.antes.first,
                titleColor: semantics.muted,
                backgroundColor: colorScheme.surfaceContainerHigh.withValues(
                  alpha: 0.55,
                ),
                textColor: colorScheme.onSurfaceVariant,
              ),
            ],
            if (display.depois.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _TextBlockSection(
                title: 'Depois',
                text: display.depois.first,
                titleColor: style.color,
                backgroundColor: semantics.warningContainer.withValues(
                  alpha: 0.35,
                ),
                textColor: colorScheme.onSurface,
              ),
            ],
            if (display.antes.isEmpty && display.depois.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Detalhes indisponíveis para este item.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ] else if (display.conteudo.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _TextBlockSection(
              title: display.isNovo ? 'Adicionado' : 'Removido',
              text: display.conteudo.first,
              titleColor: style.color,
              backgroundColor: display.isNovo
                  ? semantics.success.withValues(alpha: 0.12)
                  : colorScheme.errorContainer.withValues(alpha: 0.35),
              textColor: colorScheme.onSurface,
            ),
          ],
        ],
      ),
    );
  }

  static ({IconData icon, Color color, String label}) _styleForType(
    BuildContext context,
    String tipo,
  ) {
    final semantics = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    return switch (tipo) {
      'novo' => (
        icon: Icons.add_circle_outline,
        color: semantics.success,
        label: 'Novo',
      ),
      'removido' => (
        icon: Icons.remove_circle_outline,
        color: colorScheme.error,
        label: 'Removido',
      ),
      'alterado' => (
        icon: Icons.edit_outlined,
        color: semantics.warning,
        label: 'Alterado',
      ),
      _ => (
        icon: Icons.circle,
        color: colorScheme.onSurfaceVariant,
        label: 'Alteração',
      ),
    };
  }
}

class _TextBlockSection extends StatelessWidget {
  final String title;
  final String text;
  final Color titleColor;
  final Color backgroundColor;
  final Color textColor;

  const _TextBlockSection({
    required this.title,
    required this.text,
    required this.titleColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: theme.textTheme.labelMedium?.copyWith(color: titleColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: SelectableText(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
