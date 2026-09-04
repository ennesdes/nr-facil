import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';

/// Lista de itens granulares de uma atualização de NR.
///
/// Cada linha: ícone semântico por tipo + identificador (ex: "6.5") + resumo.
class UpdateItemsList extends StatelessWidget {
  final List<UpdateItem> items;
  final EdgeInsets padding;
  final double itemSpacing;

  const UpdateItemsList({
    required this.items,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.itemSpacing = 12,
    super.key,
  });

  static ({IconData icon, Color color}) _iconForType(
    BuildContext context,
    String tipo,
  ) {
    final semantics = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    return switch (tipo.toLowerCase()) {
      'novo' => (icon: Icons.add_circle_outline, color: semantics.success),
      'removido' => (icon: Icons.remove_circle_outline, color: colorScheme.error),
      'alterado' => (icon: Icons.edit_outlined, color: semantics.warning),
      _ => (icon: Icons.circle, color: colorScheme.onSurfaceVariant),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? itemSpacing : 0,
              ),
              child: _buildItemRow(context, item),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, UpdateItem item) {
    final textTheme = Theme.of(context).textTheme;
    final iconData = _iconForType(context, item.tipo);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
          child: Icon(iconData.icon, size: 20, color: iconData.color),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.item,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.resumo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    item.resumo,
                    style: textTheme.bodySmall,
                    softWrap: true,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
