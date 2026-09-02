import 'package:flutter/material.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;

/// App bar do leitor: número da NR, índice, favorito, busca e preferências.
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nrId;
  final bool isFavorite;
  final bool isDarkMode;
  final VoidCallback onOpenIndex;
  final VoidCallback onOpenSearch;
  final VoidCallback onToggleFavorite;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onToggleDarkMode;

  const ReaderAppBar({
    required this.nrId,
    required this.isFavorite,
    required this.isDarkMode,
    required this.onOpenIndex,
    required this.onOpenSearch,
    required this.onToggleFavorite,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onToggleDarkMode,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(nr_id.formatNrLabel(nrId)),
      centerTitle: false,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.list_alt),
          tooltip: 'Índice',
          onPressed: onOpenIndex,
        ),
        IconButton(
          icon: Icon(isFavorite ? Icons.star : Icons.star_border),
          tooltip: isFavorite ? 'Remover dos favoritos' : 'Favoritar',
          onPressed: onToggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Buscar nesta NR',
          onPressed: onOpenSearch,
        ),
        PopupMenuButton<String>(
          tooltip: 'Preferências de leitura',
          onSelected: (value) {
            switch (value) {
              case 'font_up':
                onIncreaseFontSize();
              case 'font_down':
                onDecreaseFontSize();
              case 'dark':
                onToggleDarkMode();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'font_up',
              child: ListTile(
                leading: Icon(Icons.text_increase),
                title: Text('Aumentar fonte'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'font_down',
              child: ListTile(
                leading: Icon(Icons.text_decrease),
                title: Text('Diminuir fonte'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'dark',
              child: ListTile(
                leading: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                title: Text(isDarkMode ? 'Modo claro' : 'Modo escuro'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
