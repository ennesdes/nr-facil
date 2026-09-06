import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;
import 'package:nrfacil/core/utils/responsive_layout.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_font_size_control.dart';

/// App bar do leitor: voltar, título, busca, índice e menu.
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nrId;
  final bool isFavorite;
  final bool hasPendingUpdate;
  final Rx<double> fontSize;
  final VoidCallback onBack;
  final VoidCallback onOpenIndex;
  final VoidCallback onOpenSearch;
  final VoidCallback onToggleFavorite;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;

  const ReaderAppBar({
    required this.nrId,
    required this.isFavorite,
    required this.hasPendingUpdate,
    required this.fontSize,
    required this.onBack,
    required this.onOpenIndex,
    required this.onOpenSearch,
    required this.onToggleFavorite,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveLayout.isCompactWidth(context);

    return AppBar(
      automaticallyImplyLeading: false,
      leading: Tooltip(
        message: 'Voltar para normas',
        child: BackButton(onPressed: onBack),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              nr_id.formatNrLabel(nrId),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (hasPendingUpdate) ...[
            const SizedBox(width: 8),
            const NrBadge(variant: NrBadgeVariant.update, compact: true),
          ],
        ],
      ),
      centerTitle: false,
      actions: [
        if (!compact) ...[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar nesta NR',
            onPressed: onOpenSearch,
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Índice',
            onPressed: onOpenIndex,
          ),
        ],
        PopupMenuButton<String>(
          tooltip: 'Mais opções',
          onSelected: (value) {
            switch (value) {
              case 'favorite':
                onToggleFavorite();
              case 'search':
                onOpenSearch();
              case 'index':
                onOpenIndex();
            }
          },
          itemBuilder: (context) => [
            if (compact) ...[
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Buscar nesta NR')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'index',
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Índice')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: 'favorite',
              child: Row(
                children: [
                  Icon(isFavorite ? Icons.star : Icons.star_border, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isFavorite ? 'Remover dos favoritos' : 'Favoritar',
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              enabled: false,
              padding: EdgeInsets.zero,
              child: ReaderFontSizeControl(
                fontSize: fontSize,
                onDecrease: onDecreaseFontSize,
                onIncrease: onIncreaseFontSize,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
