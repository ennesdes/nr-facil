import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/widgets/app_modal_bottom_sheet.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';
import 'package:nrfacil/features/updates/utils/update_item_display.dart';

/// Bottom sheet compartilhado para listar atualizações pendentes.
class UpdatesBottomSheet {
  UpdatesBottomSheet._();

  /// Abre o sheet com todas as NRs pendentes (contexto home).
  static Future<void> showAllPending(BuildContext context) {
    final contentService = Get.find<ContentService>();
    return show(
      context: context,
      entries: contentService.updatedNrs,
      contentService: contentService,
    );
  }

  /// Abre o sheet para uma única NR (contexto leitor).
  static Future<void> showForNr(
    BuildContext context, {
    required ManifestEntry entry,
    required NRReaderController readerController,
  }) {
    final contentService = Get.find<ContentService>();
    return show(
      context: context,
      entries: [entry],
      contentService: contentService,
      readerController: readerController,
    );
  }

  static Future<void> show({
    required BuildContext context,
    required List<ManifestEntry> entries,
    required ContentService contentService,
    NRReaderController? readerController,
  }) {
    return showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: entries.length == 1 ? 0.45 : 0.55,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Atualizações pendentes',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const NrBadge(variant: NrBadgeVariant.update),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        _NrUpdatesGroup(
                          entry: entries[i],
                          updateEntry:
                              contentService.updateEntryFor(entries[i].id),
                          showNrHeader: entries.length > 1,
                          onItemTap: (item) => _handleItemTap(
                            sheetContext: sheetContext,
                            nrId: entries[i].id,
                            item: item,
                            readerController: readerController,
                          ),
                        ),
                        if (i < entries.length - 1)
                          const SizedBox(height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void _handleItemTap({
    required BuildContext sheetContext,
    required String nrId,
    required UpdateItem item,
    NRReaderController? readerController,
  }) {
    Navigator.pop(sheetContext);

    if (readerController != null && readerController.nrId == nrId) {
      readerController.navigateToItemNumber(item.item);
      return;
    }

    ReaderNavigation.open(nrId: nrId, initialAnchor: item.item);
  }
}

class _NrUpdatesGroup extends StatelessWidget {
  final ManifestEntry entry;
  final UpdateEntry? updateEntry;
  final bool showNrHeader;
  final ValueChanged<UpdateItem> onItemTap;

  const _NrUpdatesGroup({
    required this.entry,
    required this.updateEntry,
    required this.showNrHeader,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = updateEntry?.items ?? const <UpdateItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showNrHeader) ...[
          Text(
            entry.nrLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (items.isEmpty)
          _FallbackSummaryRow(
            summary: updateEntry?.summary ??
                'Detalhes indisponíveis para esta atualização.',
          )
        else
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? AppSpacing.xs : 0,
              ),
              child: _UpdateSheetItemRow(
                item: item,
                onTap: () => onItemTap(item),
              ),
            );
          }),
      ],
    );
  }
}

class _UpdateSheetItemRow extends StatelessWidget {
  final UpdateItem item;
  final VoidCallback onTap;

  const _UpdateSheetItemRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final display = UpdateItemDisplay.fromUpdateItem(item);
    final style = _styleForType(context, display.tipo);
    final detailLabel = item.isTableChange ? 'Tabela alterada' : style.label;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
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
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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

class _FallbackSummaryRow extends StatelessWidget {
  final String summary;

  const _FallbackSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        summary,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
