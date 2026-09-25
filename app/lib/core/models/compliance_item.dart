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

  /// Palavra de gravidade (sem código I1–I4).
  String? get gradacaoSeverityWord {
    if (gradacao == null) return null;
    return switch (gradacao) {
      'I1' => 'Leve',
      'I2' => 'Média',
      'I3' => 'Grave',
      'I4' => 'Gravíssima',
      _ => null,
    };
  }

  /// Label de gradação para exibição (ex: "Gravíssima (I4)").
  String? get gradacaoLabel {
    if (gradacao == null) return null;
    final word = gradacaoSeverityWord;
    if (word != null) return '$word ($gradacao)';
    return gradacao;
  }

  /// Leitura acessível do código (diferencia I de L).
  String? get gradacaoCodeSemanticsLabel {
    if (gradacao == null || gradacao!.length < 2) return null;
    final digit = gradacao!.substring(1);
    final digitWord = switch (digit) {
      '1' => 'um',
      '2' => 'dois',
      '3' => 'três',
      '4' => 'quatro',
      _ => digit,
    };
    return 'Gradação I $digitWord';
  }

  /// Texto para compartilhar (ex.: WhatsApp com cliente).
  String toShareText() {
    final lines = <String>[
      '${nrId.toUpperCase()} — $titulo',
      if (infracao && gradacaoLabel != null) 'Gravidade: ${gradacaoLabel!}',
      if (codigoInfracao != null && codigoInfracao!.isNotEmpty)
        'Código NR-28: $codigoInfracao',
      explicacao,
      'Responsável: $responsavel',
      'Fonte: Anexo II da NR-28 (conteúdo curado — conferir texto oficial da norma).',
    ];
    return lines.join('\n');
  }

  /// Sigla do tipo (NR-28) para chips compactos.
  String? get tipoShortLabel {
    if (tipo == null) return null;
    return switch (tipo) {
      'S' => 'SST',
      'M' => 'SMO',
      _ => tipo,
    };
  }

  /// Label de tipo para exibição (tooltips e textos longos).
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
