/// Modelo do manifest.json — índice remoto de todas as NRs.
///
/// Schema autorizado em docs/architecture.md.
/// Fallbacks defensivos em fromMap() para lidar com cache corrompido ou versão antiga.
library;

class Manifest {
  final DateTime generatedAt;
  final int version;
  final List<ManifestEntry> nrs;

  Manifest({
    required this.generatedAt,
    required this.version,
    required this.nrs,
  });

  factory Manifest.fromMap(Map<String, dynamic> map) {
    try {
      final generatedAtStr = map['generated_at'] as String?;
      final generatedAt = generatedAtStr != null
          ? DateTime.parse(generatedAtStr)
          : DateTime.now();

      final version = (map['version'] as num?)?.toInt() ?? 1;

      final nrsList = (map['nrs'] as List<dynamic>?)
          ?.map((e) => ManifestEntry.fromMap(
              e is Map<String, dynamic> ? e : <String, dynamic>{}))
          .toList() ?? [];

      return Manifest(
        generatedAt: generatedAt,
        version: version,
        nrs: nrsList,
      );
    } catch (e) {
      // Manifest corrompido — retornar vazio e retentar download
      throw ManifestParseException('Falha ao parsear manifest.json: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'version': version,
      'nrs': nrs.map((e) => e.toMap()).toList(),
    };
  }

  /// Encontrar NR por ID.
  ManifestEntry? findNr(String nrId) {
    try {
      return nrs.firstWhere((nr) => nr.id == nrId);
    } catch (e) {
      return null;
    }
  }
}

/// Entrada individual de uma NR no manifest.
class ManifestEntry {
  final String id; // ex: "nr-06"
  final String title;
  final String version;
  final String hash; // hash do conteúdo convertido (.md + assets)
  final String pdfHash; // hash do PDF original
  final DateTime updatedAt;
  final String? portaria;
  final String? publicadoEm;
  final String? vigenteSde;
  final String url; // URL do .md no GitHub raw
  final String? pdfUrl; // URL do PDF original no portal MTE (opcional)
  final bool? reviewed;
  final bool? revogada; // campo opcional: true se NR foi revogada
  final String? substituiPor; // ID da NR sucessora, quando aplicável

  ManifestEntry({
    required this.id,
    required this.title,
    required this.version,
    required this.hash,
    required this.pdfHash,
    required this.updatedAt,
    this.portaria,
    this.publicadoEm,
    this.vigenteSde,
    required this.url,
    this.pdfUrl,
    this.reviewed,
    this.revogada,
    this.substituiPor,
  });

  factory ManifestEntry.fromMap(Map<String, dynamic> map) {
    try {
      final updatedAtStr = map['updated_at'] as String?;
      final updatedAt = updatedAtStr != null
          ? DateTime.parse(updatedAtStr)
          : DateTime.now();

      return ManifestEntry(
        id: map['id'] as String? ?? 'unknown',
        title: map['title'] as String? ?? 'Sem título',
        version: map['version'] as String? ?? '0.0.0',
        hash: map['hash'] as String? ?? '',
        pdfHash: map['pdf_hash'] as String? ?? '',
        updatedAt: updatedAt,
        portaria: map['portaria'] as String?,
        publicadoEm: map['publicado_em'] as String?,
        vigenteSde: map['vigente_desde'] as String?,
        url: map['url'] as String? ?? '',
        pdfUrl: map['pdf_url'] as String?,
        reviewed: map['reviewed'] as bool?,
        revogada: map['revogada'] as bool? ?? false,
        substituiPor: map['substitui_por'] as String?,
      );
    } catch (e) {
      // Entrada corrompida — retornar vazio/defaults
      throw ManifestEntryParseException(
          'Falha ao parsear entrada do manifest: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'version': version,
      'hash': hash,
      'pdf_hash': pdfHash,
      'updated_at': updatedAt.toIso8601String(),
      'portaria': portaria,
      'publicado_em': publicadoEm,
      'vigente_desde': vigenteSde,
      'url': url,
      'pdf_url': pdfUrl,
      'reviewed': reviewed,
      'revogada': revogada,
      'substitui_por': substituiPor,
    };
  }

  /// Verificar se esta NR precisa ser sincronizada.
  /// Compara o hash remoto (this.hash) com o hash local (lastSeenHash).
  bool needsSync(String? lastSeenHash) {
    if (lastSeenHash == null) {
      // Nunca baixou — precisa sincronizar
      return true;
    }
    // Compara hash remoto com o que foi visto localmente
    return hash != lastSeenHash;
  }

  /// Verificar se NR foi revogada (opcional).
  bool get isRevoked => revogada == true;
}

class ManifestParseException implements Exception {
  final String message;
  ManifestParseException(this.message);

  @override
  String toString() => 'ManifestParseException: $message';
}

class ManifestEntryParseException implements Exception {
  final String message;
  ManifestEntryParseException(this.message);

  @override
  String toString() => 'ManifestEntryParseException: $message';
}
