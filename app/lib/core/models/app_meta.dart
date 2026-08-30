/// Modelo do app_meta.json — feed de atualizações e versão mínima.
///
/// Schema: `app_meta.json` contém um histórico de mudanças (rolling window)
/// para permitir que o app mostre ao usuário quais NRs foram atualizadas
/// e o que exatamente mudou em cada uma.
///
/// Tolerante a campos ausentes e versões legadas (ex.: `items` pode não existir
/// em entradas antigas, antes da Fase 1 implementar diff granular).
library;

class AppMeta {
  final DateTime? generatedAt;
  final String minAppVersion;
  final List<UpdateEntry> updates;

  AppMeta({
    this.generatedAt,
    required this.minAppVersion,
    required this.updates,
  });

  factory AppMeta.fromJson(Map<String, dynamic> json) {
    try {
      final generatedAtStr = json['generated_at'] as String?;
      final generatedAt = generatedAtStr != null
          ? DateTime.parse(generatedAtStr)
          : null;

      final minAppVersion = json['min_app_version'] as String? ?? '0.0.0';

      final updatesList = (json['updates'] as List<dynamic>?)
          ?.map((e) => UpdateEntry.fromJson(
              e is Map<String, dynamic> ? e : <String, dynamic>{}))
          .toList() ?? [];

      return AppMeta(
        generatedAt: generatedAt,
        minAppVersion: minAppVersion,
        updates: updatesList,
      );
    } catch (e) {
      throw AppMetaParseException('Falha ao parsear app_meta.json: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt?.toIso8601String(),
      'min_app_version': minAppVersion,
      'updates': updates.map((e) => e.toJson()).toList(),
    };
  }
}

/// Entrada individual de uma atualização no feed de app_meta.
class UpdateEntry {
  final String nrId; // ex: "nr-06"
  final String title;
  final String? portaria;
  final String hash; // hash do conteúdo .md (usado pra detectar mudança)
  final String? pdfHash;
  final String summary; // resumo curto (ex: "2 itens alterados")
  final List<UpdateItem> items; // itens granulares (novo, alterado, removido)
  final DateTime? createdAt; // quando a atualização foi gerada

  UpdateEntry({
    required this.nrId,
    required this.title,
    this.portaria,
    required this.hash,
    this.pdfHash,
    required this.summary,
    this.items = const [],
    this.createdAt,
  });

  factory UpdateEntry.fromJson(Map<String, dynamic> json) {
    try {
      final createdAtStr = json['created_at'] as String?;
      final createdAt =
          createdAtStr != null ? DateTime.parse(createdAtStr) : null;

      // items pode ser ausente em entradas legadas — usar lista vazia como fallback
      final itemsList = (json['items'] as List<dynamic>?)
          ?.map((e) => UpdateItem.fromJson(
              e is Map<String, dynamic> ? e : <String, dynamic>{}))
          .toList() ?? [];

      return UpdateEntry(
        nrId: json['nr_id'] as String? ?? 'unknown',
        title: json['title'] as String? ?? 'Sem título',
        portaria: json['portaria'] as String?,
        hash: json['hash'] as String? ?? '',
        pdfHash: json['pdf_hash'] as String?,
        summary: json['summary'] as String? ?? 'Atualizado',
        items: itemsList,
        createdAt: createdAt,
      );
    } catch (e) {
      throw UpdateEntryParseException(
          'Falha ao parsear entrada de atualização: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nr_id': nrId,
      'title': title,
      'portaria': portaria,
      'hash': hash,
      'pdf_hash': pdfHash,
      'summary': summary,
      'items': items.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// Item granular de mudança dentro de uma atualização.
class UpdateItem {
  final String item; // ex: "6.5", "6.21"
  final String tipo; // "novo", "removido", "alterado"
  final String resumo; // resumo da mudança

  UpdateItem({
    required this.item,
    required this.tipo,
    required this.resumo,
  });

  factory UpdateItem.fromJson(Map<String, dynamic> json) {
    try {
      return UpdateItem(
        item: json['item'] as String? ?? 'desconhecido',
        tipo: json['tipo'] as String? ?? 'desconhecido',
        resumo: json['resumo'] as String? ?? 'Sem detalhes',
      );
    } catch (e) {
      throw UpdateItemParseException('Falha ao parsear item de atualização: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'tipo': tipo,
      'resumo': resumo,
    };
  }
}

class AppMetaParseException implements Exception {
  final String message;
  AppMetaParseException(this.message);

  @override
  String toString() => 'AppMetaParseException: $message';
}

class UpdateEntryParseException implements Exception {
  final String message;
  UpdateEntryParseException(this.message);

  @override
  String toString() => 'UpdateEntryParseException: $message';
}

class UpdateItemParseException implements Exception {
  final String message;
  UpdateItemParseException(this.message);

  @override
  String toString() => 'UpdateItemParseException: $message';
}
