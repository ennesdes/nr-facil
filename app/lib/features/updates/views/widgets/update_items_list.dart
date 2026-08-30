import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/app_meta.dart';

/// Widget que renderiza uma lista de itens granulares de atualização.
///
/// Usado na tela de Atualizações (Fase 4) e no banner do leitor (Fase 5).
/// Cada item é exibido como: ícone/emoji por tipo + identificador (ex: "6.5") + resumo.
///
/// - 🆕 para tipo "novo"
/// - ❌ para tipo "removido"
/// - ✏️ para tipo "alterado"
///
/// Sem dependência de contexto específico — recebe dados prontos via construtor.
class UpdateItemsList extends StatelessWidget {
  /// Lista de itens granulares a renderizar
  final List<UpdateItem> items;

  /// Padding externo (padrão: 16dp em todos os lados)
  final EdgeInsets padding;

  /// Espaçamento entre itens (padrão: 12dp)
  final double itemSpacing;

  const UpdateItemsList({
    required this.items,
    this.padding = const EdgeInsets.all(16),
    this.itemSpacing = 12,
    super.key,
  });

  /// Retornar emoji correspondente ao tipo de mudança
  String _getEmojiForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'novo':
        return '🆕';
      case 'removido':
        return '❌';
      case 'alterado':
        return '✏️';
      default:
        return '•';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se a lista está vazia, não renderizar nada
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

  /// Construir uma linha de item individual
  Widget _buildItemRow(BuildContext context, UpdateItem item) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji por tipo
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 2),
          child: Text(
            _getEmojiForType(item.tipo),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        // Item + resumo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item identificador (ex: "6.5") em destaque
              Text(
                item.item,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Resumo da mudança
              if (item.resumo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
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
