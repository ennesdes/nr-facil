import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_index.dart';

/// Drawer com índice de navegação (headings) da NR.
///
/// Exibe uma árvore de headings construída a partir de index.json.
/// Ao tocar em um heading, navega para ele no leitor.
class ReaderDrawer extends StatelessWidget {
  final String nrId;
  final NrIndex? index;
  final Function(String headingId) onNavigate;

  const ReaderDrawer({
    required this.nrId,
    required this.index,
    required this.onNavigate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header do drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Índice de Navegação',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  'NR ${nrId.replaceFirst('nr-', '').toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Lista de headings
          Expanded(
            child: _buildHeadingsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingsList(BuildContext context) {
    final headings = index?.headings ?? [];

    if (headings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Índice não disponível',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: headings.length,
      itemBuilder: (context, index) {
        final heading = headings[index];
        // Indentação baseada no level do heading
        final indent = (heading.level - 1) * 16.0;

        return Padding(
          padding: EdgeInsets.only(left: indent),
          child: ListTile(
            title: Text(
              heading.text,
              style: TextStyle(
                fontSize: 14 - (heading.level - 1) * 1.0,
                fontWeight: heading.level <= 2 ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              onNavigate(heading.id);
              // Fechar drawer
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }
}
