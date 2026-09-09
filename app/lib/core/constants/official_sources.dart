/// Fontes oficiais do conteúdo normativo — exigidas pela política do Google Play
/// para apps que exibem informações governamentais (Misleading Claims).
///
/// URLs em domínio gov.br permitem ao usuário verificar a informação exibida.
class OfficialSources {
  /// Portal do Ministério do Trabalho e Emprego.
  static const String mtePortalUrl =
      'https://www.gov.br/trabalho-e-emprego';

  /// Página-índice das Normas Regulamentadoras no portal oficial do MTE.
  static const String nrsIndexUrl =
      'https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/ctpp-nrs/normas-regulamentadoras-nrs';

  /// Diário Oficial da União — veículo de publicação das portarias normativas.
  static const String douUrl = 'https://www.in.gov.br/servicos/diario-oficial-da-uniao';

  /// Texto curto para disclaimers (leitor, ajustes, loja).
  static const String disclaimer =
      'Este aplicativo não é governamental. Disponibiliza conteúdo público '
      'oficial das Normas Regulamentadoras do Ministério do Trabalho e Emprego. '
      'O conteúdo não substitui a consulta às publicações oficiais no portal gov.br.';

  /// Entradas para a seção "Fontes oficiais" em Ajustes.
  static const List<OfficialSourceEntry> entries = [
    OfficialSourceEntry(
      title: 'Ministério do Trabalho e Emprego',
      subtitle: 'Órgão responsável pelas Normas Regulamentadoras',
      url: mtePortalUrl,
    ),
    OfficialSourceEntry(
      title: 'Normas Regulamentadoras (índice oficial)',
      subtitle: 'Lista e PDFs das NRs no portal gov.br',
      url: nrsIndexUrl,
    ),
    OfficialSourceEntry(
      title: 'Diário Oficial da União',
      subtitle: 'Publicação das portarias que alteram as NRs',
      url: douUrl,
    ),
  ];
}

class OfficialSourceEntry {
  const OfficialSourceEntry({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;
}
