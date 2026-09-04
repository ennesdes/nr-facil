/// Modelo para histórico de leitura de uma NR.
///
/// Rastreia quando a NR foi aberta e a posição de scroll.
/// Armazenado em GetStorage sob StorageKeys.readingHistory como Lista<Map>.
library;

class ReadingHistoryEntry {
  final String nrId;
  final DateTime lastAccessedAt;
  final double scrollPosition;
  final double scrollMaxExtent;
  final String? lastHeadingViewed;
  final String? lastItemNumber;

  ReadingHistoryEntry({
    required this.nrId,
    required this.lastAccessedAt,
    this.scrollPosition = 0.0,
    this.scrollMaxExtent = 0.0,
    this.lastHeadingViewed,
    this.lastItemNumber,
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
        scrollMaxExtent:
            (map['scroll_max_extent'] as num?)?.toDouble() ?? 0.0,
        lastHeadingViewed: map['last_heading_viewed'] as String?,
        lastItemNumber: map['last_item_number'] as String?,
      );
    } catch (e) {
      throw ReadingHistoryParseException(
          'Falha ao parsear entrada de histórico: $e');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'nr_id': nrId,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'scroll_position': scrollPosition,
      'scroll_max_extent': scrollMaxExtent,
      'last_heading_viewed': lastHeadingViewed,
      'last_item_number': lastItemNumber,
    };
  }

  int? get progressPercent {
    if (scrollMaxExtent <= 0) {
      return scrollPosition > 0 ? 100 : null;
    }
    if (scrollPosition >= scrollMaxExtent - 4) return 100;
    final ratio = (scrollPosition / scrollMaxExtent).clamp(0.0, 1.0);
    return (ratio * 100).round();
  }

  ReadingHistoryEntry copyWith({
    String? nrId,
    DateTime? lastAccessedAt,
    double? scrollPosition,
    double? scrollMaxExtent,
    String? lastHeadingViewed,
    String? lastItemNumber,
  }) {
    return ReadingHistoryEntry(
      nrId: nrId ?? this.nrId,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      scrollMaxExtent: scrollMaxExtent ?? this.scrollMaxExtent,
      lastHeadingViewed: lastHeadingViewed ?? this.lastHeadingViewed,
      lastItemNumber: lastItemNumber ?? this.lastItemNumber,
    );
  }
}

class ReadingHistoryParseException implements Exception {
  final String message;
  ReadingHistoryParseException(this.message);

  @override
  String toString() => 'ReadingHistoryParseException: $message';
}
