/// Resultado de busca dentro de uma NR aberta.
class NrSearchHit {
  /// `preamble` ou [NrSection.id]
  final String sectionId;

  /// `-1` quando o match é no título da seção; senão índice do bloco.
  final int blockIndex;

  /// Rótulo para exibição (ex.: "6.5 Responsabilidades").
  final String label;

  /// Trecho de texto com o match.
  final String snippet;

  const NrSearchHit({
    required this.sectionId,
    required this.blockIndex,
    required this.label,
    required this.snippet,
  });
}
