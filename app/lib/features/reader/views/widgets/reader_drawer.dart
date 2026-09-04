import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_index.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';

/// Drawer de navegação com seções, subitens e campo "Ir para item".
class ReaderDrawer extends StatefulWidget {
  final NrStructure? structure;
  final NrIndex? legacyIndex;
  final void Function(String target) onNavigate;
  final void Function(String itemNumber) onNavigateToItem;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;

  const ReaderDrawer({
    required this.structure,
    required this.legacyIndex,
    required this.onNavigate,
    required this.onNavigateToItem,
    required this.onExpandAll,
    required this.onCollapseAll,
    super.key,
  });

  @override
  State<ReaderDrawer> createState() => _ReaderDrawerState();
}

class _ReaderDrawerState extends State<ReaderDrawer> {
  final _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final structure = widget.structure;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'Índice',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: const InputDecoration(
                        hintText: 'Ir para item (ex.: 6.5.1)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: _submitItem,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Ir',
                    onPressed: () => _submitItem(_itemController.text),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onExpandAll,
                    icon: const Icon(Icons.unfold_more, size: 18),
                    label: const Text('Expandir tudo'),
                  ),
                  TextButton.icon(
                    onPressed: widget.onCollapseAll,
                    icon: const Icon(Icons.unfold_less, size: 18),
                    label: const Text('Recolher'),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.5)),
            Expanded(
              child: structure != null && structure.sections.isNotEmpty
                  ? _buildStructureList(structure)
                  : _buildLegacyIndex(),
            ),
          ],
        ),
      ),
    );
  }

  void _submitItem(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    widget.onNavigateToItem(trimmed);
    Navigator.of(context).pop();
  }

  Widget _buildStructureList(NrStructure structure) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        if (structure.preamble.blocks.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Publicação e alterações'),
            onTap: () {
              widget.onNavigate('preamble');
              Navigator.of(context).pop();
            },
          ),
        ...structure.sections.map((section) {
          final items = section.blocks
              .whereType<NrItemBlock>()
              .where((b) => b.number.isNotEmpty)
              .toList();

          if (items.isEmpty) {
            return ListTile(
              title: Text(
                section.displayTitle,
                style: textTheme.titleSmall,
              ),
              onTap: () {
                widget.onNavigate(section.id);
                Navigator.of(context).pop();
              },
            );
          }

          return ExpansionTile(
            title: Text(
              section.displayTitle,
              style: textTheme.titleSmall,
            ),
            children: [
              ListTile(
                title: Text('Seção ${section.number}'),
                onTap: () {
                  widget.onNavigate(section.id);
                  Navigator.of(context).pop();
                },
              ),
              ...items.map(
                (item) => ListTile(
                  title: Text(
                    item.number,
                    style: textTheme.labelMedium,
                  ),
                  subtitle: Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    widget.onNavigateToItem(item.number);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLegacyIndex() {
    final headings = widget.legacyIndex?.headings ?? [];
    if (headings.isEmpty) {
      return const EmptyState(
        icon: Icons.list_alt,
        title: 'Índice indisponível',
        body: 'O índice desta NR não pôde ser carregado.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: headings.length,
      itemBuilder: (context, index) {
        final heading = headings[index];
        return ListTile(
          title: Text(heading.text),
          onTap: () {
            widget.onNavigate(heading.text);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
