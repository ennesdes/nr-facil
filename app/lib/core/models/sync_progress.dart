/// Resultado de [ContentService.syncAllContent].
class SyncAllContentResult {
  final bool success;
  final int downloadedCount;
  final int totalToDownload;
  final bool reachedNetwork;
  final bool cancelled;

  const SyncAllContentResult({
    required this.success,
    required this.downloadedCount,
    required this.totalToDownload,
    required this.reachedNetwork,
    this.cancelled = false,
  });
}

/// Progresso reativo do download em massa ("Baixar tudo para offline").
class BulkSyncProgress {
  final int completed;
  final int total;
  final String? currentNrLabel;
  final BulkSyncPhase phase;

  const BulkSyncProgress({
    required this.completed,
    required this.total,
    required this.phase,
    this.currentNrLabel,
  });

  double get fraction => total > 0 ? completed / total : 0;

  int get percent => (fraction * 100).round().clamp(0, 100);

  bool get isActive => phase != BulkSyncPhase.idle;
}

enum BulkSyncPhase {
  idle,
  preparing,
  downloading,
}
