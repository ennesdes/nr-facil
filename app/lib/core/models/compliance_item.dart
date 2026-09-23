/// Modelo de item do checklist de conformidade.
///
/// Cada item representa um requisito de conformidade de uma NR,
/// com indicação de infração e gradação quando aplicável.
library;

class ComplianceItem {
  final String nrId; // ex: "nr-05"
  final String itemNumber; // ex: "5.2.1, 5.8.1"
  final String titulo;
  final bool infracao;
  final String? gradacao; // I1-I4, opcional
  final String? tipo; // S (Segurança do Trabalho) ou M (Medicina do Trabalho), opcional
  final String? codigoInfracao;
  final String explicacao;
  final String responsavel;
  final List<String> riskFactors; // ids de fatores de risco que a tornam aplicável
  final String readerAnchorId; // âncora no leitor da NR

  ComplianceItem({
    required this.nrId,
    required this.itemNumber,
    required this.titulo,
    required this.infracao,
    this.gradacao,
    this.tipo,
    this.codigoInfracao,
    required this.explicacao,
    required this.responsavel,
    required this.riskFactors,
    required this.readerAnchorId,
  });

  factory ComplianceItem.fromMap(Map<String, dynamic> map) {
    try {
      return ComplianceItem(
        nrId: map['nr_id'] as String? ?? 'unknown',
        itemNumber: map['item_number'] as String? ?? '',
        titulo: map['titulo'] as String? ?? 'Sem título',
        infracao: map['infracao'] as bool? ?? false,
        gradacao: map['gradacao'] as String?,
        tipo: map['tipo'] as String?,
        codigoInfracao: map['codigo_infracao'] as String?,
        explicacao: map['explicacao'] as String? ?? '',
        responsavel: map['responsavel'] as String? ?? '',
        riskFactors: (map['risk_factors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        readerAnchorId: map['reader_anchor_id'] as String? ?? '',
      );
    } catch (e) {
      throw ComplianceItemParseException(
        'Falha ao parsear item de conformidade: $e',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nr_id': nrId,
      'item_number': itemNumber,
      'titulo': titulo,
      'infracao': infracao,
      'gradacao': gradacao,
      'tipo': tipo,
      'codigo_infracao': codigoInfracao,
      'explicacao': explicacao,
      'responsavel': responsavel,
      'risk_factors': riskFactors,
      'reader_anchor_id': readerAnchorId,
    };
  }

  /// Label de gradação para exibição (ex: "I4 - Gravíssima")
  String? get gradacaoLabel {
    if (gradacao == null) return null;
    return switch (gradacao) {
      'I1' => 'I1 - Leve',
      'I2' => 'I2 - Média',
      'I3' => 'I3 - Grave',
      'I4' => 'I4 - Gravíssima',
      _ => gradacao,
    };
  }

  /// Texto para compartilhar (ex.: WhatsApp com cliente).
  String toShareText() {
    final lines = <String>[
      '${nrId.toUpperCase()} — $titulo',
      if (infracao && gradacaoLabel != null) 'Infração: ${gradacaoLabel!}',
      if (codigoInfracao != null && codigoInfracao!.isNotEmpty)
        'Código NR-28: $codigoInfracao',
      explicacao,
      'Responsável: $responsavel',
      'Fonte: Anexo II da NR-28 (conteúdo curado — conferir texto oficial da norma).',
    ];
    return lines.join('\n');
  }

  /// Label de tipo para exibição
  String? get tipoLabel {
    if (tipo == null) return null;
    return switch (tipo) {
      'S' => 'Segurança do Trabalho',
      'M' => 'Medicina do Trabalho',
      _ => tipo,
    };
  }
}

class ComplianceItemParseException implements Exception {
  final String message;
  ComplianceItemParseException(this.message);

  @override
  String toString() => 'ComplianceItemParseException: $message';
}
