/// Modelo para histórico de leitura de uma NR.
///
/// Rastreia quando a NR foi aberta e a posição de scroll.
/// Armazenado em GetStorage sob StorageKeys.readingHistory como Lista<Map>.
library;

class ReadingHistoryEntry {
  final String nrId;
  final DateTime lastAccessedAt;
  final double scrollPosition; // posição do scroll no leitor (em pixels)
  final String? lastHeadingViewed; // último heading visto (para navegação rápida)

  ReadingHistoryEntry({
    required this.nrId,
    required this.lastAccessedAt,
    this.scrollPosition = 0.0,
    this.lastHeadingViewed,
  });

  factory ReadingHistoryEntry.fromMap(Map<String, dynamic> map) {
    try {
      final lastAccessedStr = map['last_accessed_at'] as String?;
      final lastAccessedAt = lastAccessedStr != null
          ? DateTime.parse(lastAccessedStr)
          : DateTime.now();

      return ReadingHistoryEntry(
        nrId: map['nr_id'] as String? ?? 'unknown',
        lastAccessedAt: lastAccessedAt,
        scrollPosition: (map['scroll_position'] as num?)?.toDouble() ?? 0.0,
        lastHeadingViewed: map['last_heading_viewed'] as String?,
      );
    } catch (e) {
      // Entrada corrompida — retornar com valores padrão
      throw ReadingHistoryParseException(
          'Falha ao parsear entrada de histórico: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nr_id': nrId,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'scroll_position': scrollPosition,
      'last_heading_viewed': lastHeadingViewed,
    };
  }

  /// Criar cópia com campos atualizados.
  ReadingHistoryEntry copyWith({
    String? nrId,
    DateTime? lastAccessedAt,
    double? scrollPosition,
    String? lastHeadingViewed,
  }) {
    return ReadingHistoryEntry(
      nrId: nrId ?? this.nrId,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      lastHeadingViewed: lastHeadingViewed ?? this.lastHeadingViewed,
    );
  }
}

class ReadingHistoryParseException implements Exception {
  final String message;
  ReadingHistoryParseException(this.message);

  @override
  String toString() => 'ReadingHistoryParseException: $message';
}
