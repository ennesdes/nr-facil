/// Textos de UI do módulo de conformidade / autuações (NR-28).
library;

class ComplianceCopy {
  ComplianceCopy._();

  static const tabLabel = 'Autuações';
  static const screenTitle = 'Checklist';
  static const screenSubtitle =
      'Itens que podem gerar autuação — amostra curada';

  static const profileIntro =
      'Com setor e fatores de risco, montamos uma lista dos principais '
      'itens autuáveis (Anexo II da NR-28) para sua realidade. '
      'Não é lista completa de todas as NRs nem substitui consultoria em SST.';

  static const progressHint =
      'Marcação só registra sua verificação interna — não comprova conformidade legal.';

  static const itemsSectionTitle = 'Itens de atenção (possível autuação)';

  static const nr28CodePrefix = 'NR-28 Anexo II';

  static const infoSheetTitle = 'Sobre esta lista';

  static String infoSheetScope(String updatedAt) =>
      'Itens alinhados ao Anexo II da NR-28 (possível autuação). '
      'Regras atualizadas em $updatedAt.';

  static const infoSheetDisclaimer =
      'Lista curada para orientar sua verificação interna. '
      'Não substitui especialista de SST nem o texto oficial das normas.';

  static const coverageTitle = 'O que não está incluído';
  static const coverageBullets = [
    'Apenas parte das NRs vigentes (~13 normas, itens centrais de cada uma).',
    'Conteúdo curado com apoio de IA — revisão por profissional de SST em andamento.',
    'Não inclui valor de multa, processo administrativo nem parecer jurídico.',
  ];

  static const profileMissingTitle = 'Configure sua empresa';
  static const profileMissingBody =
      'Para ver os itens autuáveis do seu setor, informe porte, atividade e fatores de risco.';

  static const emptyItemsTitle = 'Nenhum item para este perfil';
  static const emptyItemsBody =
      'Ajuste o setor ou marque fatores de risco no perfil. '
      'Itens do setor entram automaticamente; fatores somam exigências extras.';

  /// Mensagem interna do [ChecklistController] quando não há perfil salvo.
  static const profileMissingError = 'Perfil não encontrado';
}
