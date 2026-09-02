import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_index.dart';
import 'package:nrfacil/core/models/nr_structure.dart';

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

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Índice',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        hintText: 'Ir para item (ex.: 6.5.1)',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (value) {
                        final trimmed = value.trim();
                        if (trimmed.isEmpty) return;
                        widget.onNavigateToItem(trimmed);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Ir',
                    onPressed: () {
                      final trimmed = _itemController.text.trim();
                      if (trimmed.isEmpty) return;
                      widget.onNavigateToItem(trimmed);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
            const Divider(height: 1),
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

  Widget _buildStructureList(NrStructure structure) {
    return ListView(
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
                style: const TextStyle(fontWeight: FontWeight.w600),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            children: [
              ListTile(
                dense: true,
                title: Text('Seção ${section.number}'),
                onTap: () {
                  widget.onNavigate(section.id);
                  Navigator.of(context).pop();
                },
              ),
              ...items.map(
                (item) => ListTile(
                  dense: true,
                  title: Text(item.number),
                  subtitle: Text(
                    item.text,
                    maxLines: 1,
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
      return const Center(child: Text('Índice indisponível'));
    }

    return ListView.builder(
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
