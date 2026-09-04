import 'package:flutter/material.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;
import 'package:nrfacil/features/reader/views/widgets/reader_font_size_control.dart';

/// App bar do leitor: voltar, título, busca, índice e menu.
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nrId;
  final bool isFavorite;
  final double fontSize;
  final VoidCallback onBack;
  final VoidCallback onOpenIndex;
  final VoidCallback onOpenSearch;
  final VoidCallback onToggleFavorite;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;

  const ReaderAppBar({
    required this.nrId,
    required this.isFavorite,
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
    return AppBar(
      automaticallyImplyLeading: false,
      leading: Tooltip(
        message: 'Voltar para normas',
        child: BackButton(onPressed: onBack),
      ),
      title: Text(nr_id.formatNrLabel(nrId)),
      centerTitle: false,
      elevation: 1,
      actions: [
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
        PopupMenuButton<String>(
          tooltip: 'Mais opções',
          onSelected: (value) {
            if (value == 'favorite') onToggleFavorite();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorite',
              child: ListTile(
                leading: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                ),
                title: Text(
                  isFavorite ? 'Remover dos favoritos' : 'Favoritar',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              enabled: false,
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
