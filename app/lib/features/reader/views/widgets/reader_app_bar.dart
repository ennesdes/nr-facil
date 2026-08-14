import 'package:flutter/material.dart';

/// App bar customizada para o leitor de NRs.
///
/// Exibe:
/// - Título da NR
/// - Botão para abrir drawer (índice)
/// - Botões de ajuste de fonte (+ e -)
/// - Botão de dark mode
class ReaderAppBar extends PreferredSize {
  final String nrId;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;

  ReaderAppBar({
    required this.nrId,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onToggleDarkMode,
    required this.isDarkMode,
  }) : super(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: _AppBarContent(
      nrId: nrId,
      onIncreaseFontSize: onIncreaseFontSize,
      onDecreaseFontSize: onDecreaseFontSize,
      onToggleDarkMode: onToggleDarkMode,
      isDarkMode: isDarkMode,
    ),
  );
}

class _AppBarContent extends StatelessWidget {
  final String nrId;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final VoidCallback onToggleDarkMode;
  final bool isDarkMode;

  const _AppBarContent({
    required this.nrId,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    required this.onToggleDarkMode,
    required this.isDarkMode,
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
