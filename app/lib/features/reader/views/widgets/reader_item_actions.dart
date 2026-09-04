import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nrfacil/core/widgets/app_modal_bottom_sheet.dart';
import 'package:nrfacil/features/reader/utils/item_citation_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Ações de copiar/compartilhar referência de um item normativo.
class ReaderItemActions {
  static Future<void> showMenu({
    required BuildContext context,
    required String nrId,
    required String itemNumber,
    required String text,
  }) async {
    final action = await showAppModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copiar referência'),
            onTap: () => Navigator.pop(context, 'copy'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text('Compartilhar item $itemNumber'),
            onTap: () => Navigator.pop(context, 'share'),
          ),
        ],
      ),
    );

    if (action == null || !context.mounted) return;

    final citation = formatItemCitation(
      nrId: nrId,
      itemNumber: itemNumber,
      text: text,
    );

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: citation));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referência copiada')),
        );
      }
    } else if (action == 'share') {
      await SharePlus.instance.share(ShareParams(text: citation));
    }
  }
}
