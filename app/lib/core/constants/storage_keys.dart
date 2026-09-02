/// Chaves centralizadas para armazenamento local (GetStorage + path_provider).
///
/// Nunca usar string literal solta — sempre referenciar constante daqui.
class StorageKeys {
  // Prefixo para todas as chaves GetStorage
  static const String _prefix = 'nr_facil_';

  // Metadados de sincronização
  static const String lastSyncedAt = '${_prefix}last_synced_at';
  static const String manifestHash = '${_prefix}manifest_hash';

  // Por NR: hash sincronizado vs. hash visto
  static String nrLastSyncedHash(String nrId) => '${_prefix}nr_${nrId}_synced_hash';
  static String nrLastSeenHash(String nrId) => '${_prefix}nr_${nrId}_seen_hash';

  // Favoritos
  static const String favoriteNrs = '${_prefix}favorite_nrs';

  // Histórico
  static const String readingHistory = '${_prefix}reading_history';

  static const String lastOpenedNr = '${_prefix}last_opened_nr';
  static const String lastOpenedNrScroll = '${_prefix}last_opened_nr_scroll';

  // Preferências do leitor
  static const String readerFontSize = '${_prefix}reader_font_size';
  static const String readerDarkMode = '${_prefix}reader_dark_mode';
}
