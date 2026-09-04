import 'package:flutter/material.dart';

/// Botão de ícone padronizado para ações em tiles de NR.
class NrTileIconButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  const NrTileIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
    );
  }
}
