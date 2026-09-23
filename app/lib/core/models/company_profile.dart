/// Modelo do perfil da empresa.
///
/// Armazena as informações de porte, atividade e fatores de risco
/// que determinam quais itens de conformidade são aplicáveis.
///
/// v1: perfil único por instalação (id fixo "default")
/// Preparado para evoluir para lista de perfis sem reescrever a serialização.
library;

class CompanyProfile {
  final String id; // "default" em v1, preparado pra evoluir
  final String porte; // ex: "até 10", "11 a 50", "51 a 100", "101 a 500", ">500"
  final String segmentoId; // id de um Segment do compliance.json, ex: "industria"
  final List<String> riskFactors; // ids de fatores de risco identificados

  CompanyProfile({
    required this.id,
    required this.porte,
    required this.segmentoId,
    required this.riskFactors,
  });

  factory CompanyProfile.empty() {
    return CompanyProfile(
      id: 'default',
      porte: '',
      segmentoId: '',
      riskFactors: [],
    );
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    try {
      return CompanyProfile(
        id: map['id'] as String? ?? 'default',
        porte: map['porte'] as String? ?? '',
        segmentoId: map['segmento_id'] as String? ?? '',
        riskFactors: (map['risk_factors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
    } catch (e) {
      throw CompanyProfileParseException(
        'Falha ao parsear perfil de empresa: $e',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'porte': porte,
      'segmento_id': segmentoId,
      'risk_factors': riskFactors,
    };
  }

  /// Verifica se o perfil está completo (todos os campos preenchidos).
  bool get isComplete => porte.isNotEmpty && segmentoId.isNotEmpty;

  /// Retorna uma cópia com campos atualizados.
  CompanyProfile copyWith({
    String? id,
    String? porte,
    String? segmentoId,
    List<String>? riskFactors,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      porte: porte ?? this.porte,
      segmentoId: segmentoId ?? this.segmentoId,
      riskFactors: riskFactors ?? this.riskFactors,
    );
  }
}

class CompanyProfileParseException implements Exception {
  final String message;
  CompanyProfileParseException(this.message);

  @override
  String toString() => 'CompanyProfileParseException: $message';
}
