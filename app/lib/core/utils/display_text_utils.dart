/// Formatação de texto para exibição na UI (não altera dados armazenados).
library;

const _preservedAcronyms = {
  'EPI',
  'CIPA',
  'SESMT',
  'NR',
  'PPRA',
  'PCMSO',
  'LTCAT',
  'ASO',
  'PGR',
  'GRO',
};

/// Converte título de NR em sentence case para leitura em listas.
///
/// Ex.: `"DISPOSIÇÕES GERAIS"` → `"Disposições gerais"`.
/// Siglas conhecidas permanecem em maiúsculas.
String formatNrTitleForDisplay(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return trimmed;

  final lower = trimmed.toLowerCase();
  final words = lower.split(RegExp(r'\s+'));
  final formatted = words.map(_formatWord).join(' ');

  if (formatted.isEmpty) return formatted;
  return formatted[0].toUpperCase() + formatted.substring(1);
}

String _formatWord(String word) {
  if (word.isEmpty) return word;

  final stripped = word.replaceAll(RegExp(r'[^\wÀ-ÿ-]'), '');
  final upper = stripped.toUpperCase();
  if (_preservedAcronyms.contains(upper)) {
    return word.replaceFirst(stripped, upper);
  }

  return word;
}
