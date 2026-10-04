/// Motivo pelo qual o usuário concluiu a revisão de uma atualização de NR.
enum AcknowledgeUpdateReason {
  /// Abriu o bottom sheet / painel com o diff.
  sheetView,

  /// Tocou em um item alterado na lista de mudanças.
  itemTap,

  /// Fechou o banner no leitor (X).
  bannerDismiss,

  /// Confirmou revisão quando só há resumo (`summary`) sem itens.
  summaryButton,
}
