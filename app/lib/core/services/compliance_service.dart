/// ComplianceService — carrega e gerencia o dataset de conformidade.
///
/// O dataset é bundlado como asset estático (compliance.json),
/// não sincronizado via GitHub raw. Atualiza junto com nova versão do app.
///
/// Responsabilidades:
/// - Carregar compliance.json do bundle
/// - Consultar itens por NR
/// - Filtrar itens por fatores de risco
/// - Expor data de atualização do dataset para disclaimer
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/compliance_item.dart';
import '../utils/app_logger.dart';

class RiskFactor {
  final String id;
  final String label;

  RiskFactor({required this.id, required this.label});

  factory RiskFactor.fromMap(Map<String, dynamic> map) {
    return RiskFactor(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
    };
  }
}

/// Segmento/atividade da empresa — leva um conjunto-base de NRs aplicáveis
/// independente dos fatores de risco marcados (ver [ComplianceService.getApplicableItems]).
class Segment {
  final String id;
  final String label;
  final List<String> nrIdsBase;

  Segment({required this.id, required this.label, required this.nrIdsBase});

  factory Segment.fromMap(Map<String, dynamic> map) {
    return Segment(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      nrIdsBase: (map['nr_ids_base'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'nr_ids_base': nrIdsBase,
    };
  }
}

class ComplianceDataset {
  // ignore: non_constant_identifier_names
  final String atualizado_em; // Snake case do JSON é intencional
  final String aviso;
  final List<RiskFactor> riskFactors;
  final List<Segment> segments;
  final List<ComplianceItem> items;

  ComplianceDataset({
    required this.atualizado_em,
    required this.aviso,
    required this.riskFactors,
    this.segments = const [],
    required this.items,
  });

  factory ComplianceDataset.fromMap(Map<String, dynamic> map) {
    try {
      return ComplianceDataset(
        atualizado_em: map['atualizado_em'] as String? ?? 'desconhecida',
        aviso: map['aviso'] as String? ?? '',
        riskFactors: (map['risk_factors'] as List<dynamic>?)
                ?.map((e) => RiskFactor.fromMap(
                      e is Map<String, dynamic> ? e : <String, dynamic>{},
                    ))
                .toList() ??
            [],
        segments: (map['segments'] as List<dynamic>?)
                ?.map((e) => Segment.fromMap(
                      e is Map<String, dynamic> ? e : <String, dynamic>{},
                    ))
                .toList() ??
            [],
        items: (map['items'] as List<dynamic>?)
                ?.map((e) => ComplianceItem.fromMap(
                      e is Map<String, dynamic> ? e : <String, dynamic>{},
                    ))
                .toList() ??
            [],
      );
    } catch (e) {
      throw ComplianceDatasetParseException(
        'Falha ao parsear dataset de conformidade: $e',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'atualizado_em': atualizado_em,
      'aviso': aviso,
      'risk_factors': riskFactors.map((e) => e.toMap()).toList(),
      'segments': segments.map((e) => e.toMap()).toList(),
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}

class ComplianceService extends GetxService {
  late ComplianceDataset dataset;

  /// Se o dataset carregou com sucesso
  final isLoaded = false.obs;

  /// Mensagem de erro ao carregar (se houver)
  final loadError = RxnString();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadDataset();
  }

  /// Carregar compliance.json do bundle.
  Future<void> _loadDataset() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/compliance/compliance.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      dataset = ComplianceDataset.fromMap(json);
      isLoaded.value = true;
      AppLogger.info('ComplianceService: dataset carregado com sucesso');
    } catch (e, st) {
      AppLogger.error('Erro ao carregar compliance.json', e, st);
      loadError.value = 'Falha ao carregar dataset de conformidade: $e';
      // Dataset vazio — nunca bloqueia o app
      dataset = ComplianceDataset(
        atualizado_em: 'desconhecida',
        aviso: '',
        riskFactors: [],
        segments: [],
        items: [],
      );
      isLoaded.value = false;
    }
  }

  /// Buscar todos os fatores de risco disponíveis.
  List<RiskFactor> getRiskFactors() => dataset.riskFactors;

  /// Buscar todos os segmentos/atividades disponíveis.
  List<Segment> getSegments() => dataset.segments;

  /// Buscar itens por NR.
  List<ComplianceItem> getItemsByNr(String nrId) {
    return dataset.items
        .where((item) => item.nrId.toLowerCase() == nrId.toLowerCase())
        .toList();
  }

  /// Buscar itens aplicáveis ao segmento e/ou fatores de risco informados.
  ///
  /// Regra aditiva (OR): um item aparece se a NR dele está no `nr_ids_base`
  /// do segmento **ou** se um dos fatores de risco do item bate com os
  /// informados — nunca duplicado quando os dois critérios batem no mesmo item.
  /// Se `segmentoId` não corresponde a nenhum segmento e `riskFactors` está
  /// vazio, retorna lista vazia (nenhum item aplicável).
  List<ComplianceItem> getApplicableItems(
    String segmentoId,
    List<String> riskFactors,
  ) {
    if (segmentoId.isEmpty && riskFactors.isEmpty) {
      return [];
    }

    Segment? segment;
    for (final s in dataset.segments) {
      if (s.id == segmentoId) {
        segment = s;
        break;
      }
    }
    final segmentNrIds = segment?.nrIdsBase.toSet() ?? <String>{};
    final riskFactorSet = riskFactors.toSet();

    final seenKeys = <String>{};
    final applicableItems = <ComplianceItem>[];
    for (final item in dataset.items) {
      final matchesSegment = segmentNrIds.contains(item.nrId);
      final matchesRiskFactor =
          item.riskFactors.any((factor) => riskFactorSet.contains(factor));
      if (matchesSegment || matchesRiskFactor) {
        final key = '${item.nrId}::${item.itemNumber}';
        if (seenKeys.add(key)) {
          applicableItems.add(item);
        }
      }
    }

    return applicableItems;
  }

  /// Buscar item específico por NR e item_number.
  ComplianceItem? getItem(String nrId, String itemNumber) {
    try {
      return dataset.items.firstWhere(
        (item) =>
            item.nrId.toLowerCase() == nrId.toLowerCase() &&
            item.itemNumber == itemNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Data de atualização do dataset em formato display.
  String get atualizadoEm => dataset.atualizado_em;

  /// Aviso/disclaimer do dataset.
  String get aviso => dataset.aviso;

  /// Chave para agrupar itens por NR.
  static String itemStorageKey(String nrId, String itemNumber) =>
      'compliance_item_${nrId}_${itemNumber}_checked';
}

class ComplianceDatasetParseException implements Exception {
  final String message;
  ComplianceDatasetParseException(this.message);

  @override
  String toString() => 'ComplianceDatasetParseException: $message';
}
