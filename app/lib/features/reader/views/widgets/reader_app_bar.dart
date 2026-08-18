import 'package:flutter/material.dart';

/// App bar customizada para o leitor de NRs.
///
/// Exibe:
/// - Título da NR
/// - Botão para abrir drawer (índice)
/// - Botões de ajuste de fonte (+ e -)
/// - Botão de dark mode
/// - Botão de favorito
class ReaderAppBar extends PreferredSize {
  final String nrId;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  ReaderAppBar({
    required this.nrId,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onToggleDarkMode,
    required this.isDarkMode,
    required this.isFavorite,
    required this.onToggleFavorite,
    super.key,
  }) : super(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: _AppBarContent(
      nrId: nrId,
      onIncreaseFontSize: onIncreaseFontSize,
      onDecreaseFontSize: onDecreaseFontSize,
      onToggleDarkMode: onToggleDarkMode,
      isDarkMode: isDarkMode,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
    ),
  );
}

class _AppBarContent extends StatelessWidget {
  final String nrId;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _AppBarContent({
    required this.nrId,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onToggleDarkMode,
    required this.isDarkMode,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('NR ${nrId.replaceFirst('nr-', '').toUpperCase()}'),
      centerTitle: false,
      elevation: 1,
      actions: [
        // Aumentar fonte
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Aumentar fonte',
          onPressed: onIncreaseFontSize,
        ),

        // Diminuir fonte
        IconButton(
          icon: const Icon(Icons.remove),
          tooltip: 'Diminuir fonte',
          onPressed: onDecreaseFontSize,
        ),

        // Dark mode toggle
        IconButton(
          icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          tooltip: isDarkMode ? 'Modo claro' : 'Modo escuro',
          onPressed: onToggleDarkMode,
        ),

        // Favorito toggle
        IconButton(
          icon: Icon(isFavorite ? Icons.star : Icons.star_border),
          tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          onPressed: onToggleFavorite,
        ),

        // Menu (future: share, etc)
        PopupMenuButton<String>(
          onSelected: (value) {
            // Future: implementar ações adicionais
          },
          itemBuilder: (BuildContext context) {
            return [
              // Placeholder para ações futuras
            ];
          },
        ),
      ],
    );
  }
}
