/// Modelo para histórico de leitura de uma NR.
///
/// Rastreia quando a NR foi aberta e a posição de scroll.
/// Armazenado em GetStorage sob StorageKeys.readingHistory como Lista<Map>.
library;

import 'package:nrfacil/features/reader/utils/reader_scroll_restore.dart';

class ReadingHistoryEntry {
  final String nrId;
  final DateTime lastAccessedAt;
  final double scrollPosition;
  final double scrollMaxExtent;
  final String? lastHeadingViewed;
  final String? lastItemNumber;

  /// Seção/bloco exatos no leitor estruturado (parágrafos, tabelas, etc.).
  final String? lastSectionId;
  final int? lastBlockIndex;

  /// Razão de scroll salva (0.0–1.0) — fonte primária para restaurar posição.
  final double? scrollRatio;

  /// Percentual estrutural salvo pelo leitor (0–100), quando disponível.
  final int? progressPercent;

  ReadingHistoryEntry({
    required this.nrId,
    required this.lastAccessedAt,
    this.scrollPosition = 0.0,
    this.scrollMaxExtent = 0.0,
    this.lastHeadingViewed,
    this.lastItemNumber,
    this.lastSectionId,
    this.lastBlockIndex,
    this.scrollRatio,
    this.progressPercent,
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
        scrollMaxExtent: (map['scroll_max_extent'] as num?)?.toDouble() ?? 0.0,
        lastHeadingViewed: map['last_heading_viewed'] as String?,
        lastItemNumber: map['last_item_number'] as String?,
        lastSectionId: map['last_section_id'] as String?,
        lastBlockIndex: (map['last_block_index'] as num?)?.toInt(),
        scrollRatio: (map['scroll_ratio'] as num?)?.toDouble(),
        progressPercent: (map['progress_percent'] as num?)?.toInt(),
      );
    } catch (e) {
      throw ReadingHistoryParseException(
        'Falha ao parsear entrada de histórico: $e',
      );
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
      if (lastSectionId != null) 'last_section_id': lastSectionId,
      if (lastBlockIndex != null) 'last_block_index': lastBlockIndex,
      if (scrollRatio != null) 'scroll_ratio': scrollRatio,
      if (progressPercent != null) 'progress_percent': progressPercent,
    };
  }

  /// Fallback por scroll quando o percentual estrutural não foi salvo.
  int? get scrollProgressPercent {
    if (scrollMaxExtent <= 0) return null;
    if (scrollPosition >= scrollMaxExtent - 4) return 100;
    final ratio = (scrollPosition / scrollMaxExtent).clamp(0.0, 1.0);
    return (ratio * 100).round();
  }

  /// Percentual efetivo para exibição (estrutural preferido, scroll como fallback).
  int? get effectiveProgressPercent => progressPercent ?? scrollProgressPercent;

  /// Razão efetiva de scroll para restaurar posição (0.0–1.0).
  double get effectiveScrollRatio => effectiveScrollRatioFromEntry(
    scrollRatio: scrollRatio,
    scrollPosition: scrollPosition,
    scrollMaxExtent: scrollMaxExtent,
  );

  /// Há posição salva relevante para "continuar leitura".
  bool get hasSavedReadingPosition =>
      (lastSectionId != null && lastBlockIndex != null) ||
      (lastItemNumber != null && lastItemNumber!.isNotEmpty) ||
      effectiveScrollRatio > 0.01;

  ReadingHistoryEntry copyWith({
    String? nrId,
    DateTime? lastAccessedAt,
    double? scrollPosition,
    double? scrollMaxExtent,
    String? lastHeadingViewed,
    String? lastItemNumber,
    String? lastSectionId,
    int? lastBlockIndex,
    double? scrollRatio,
    int? progressPercent,
  }) {
    return ReadingHistoryEntry(
      nrId: nrId ?? this.nrId,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      scrollMaxExtent: scrollMaxExtent ?? this.scrollMaxExtent,
      lastHeadingViewed: lastHeadingViewed ?? this.lastHeadingViewed,
      lastItemNumber: lastItemNumber ?? this.lastItemNumber,
      lastSectionId: lastSectionId ?? this.lastSectionId,
      lastBlockIndex: lastBlockIndex ?? this.lastBlockIndex,
      scrollRatio: scrollRatio ?? this.scrollRatio,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}

class ReadingHistoryParseException implements Exception {
  final String message;
  ReadingHistoryParseException(this.message);

  @override
  String toString() => 'ReadingHistoryParseException: $message';
}
