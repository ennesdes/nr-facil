import 'package:flutter/material.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;

/// App bar minimalista do leitor: número da NR + busca.
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nrId;
  final VoidCallback onOpenSearch;

  const ReaderAppBar({
    required this.nrId,
    required this.onOpenSearch,
    super.key,
  });

  static String formatNrLabel(String nrId) => nr_id.formatNrLabel(nrId);

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
          icon: const Icon(Icons.search),
          tooltip: 'Buscar nesta NR',
          onPressed: onOpenSearch,
        ),
      ],
    );
  }
}
