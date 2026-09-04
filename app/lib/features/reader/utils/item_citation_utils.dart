import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;

/// Formata citação de um item normativo para copiar/compartilhar.
String formatItemCitation({
  required String nrId,
  required String itemNumber,
  required String text,
}) {
  final label = nr_id.formatNrLabel(nrId);
  final trimmed = text.trim();
  final quoted = trimmed.isEmpty ? '' : '\n"$trimmed"\n';
  return '$label — Item $itemNumber$quoted\nFonte: $label';
}
