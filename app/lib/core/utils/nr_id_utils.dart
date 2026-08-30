/// Utilitários para IDs de NR (`nr-06` → `NR-06`).
int parseNrNumber(String nrId) {
  final match = RegExp(r'nr-(\d+)$', caseSensitive: false).firstMatch(nrId);
  return match != null ? int.parse(match.group(1)!) : 0;
}

String formatNrLabel(String nrId) {
  final number = nrId.replaceFirst(RegExp(r'^nr-', caseSensitive: false), '');
  return 'NR-$number';
}
