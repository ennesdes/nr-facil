/// IDs de semântica para testes E2E do bloco Gestão (Settings / Atualizações / Ads).
///
/// Cobre: página de ajustes (tema, links), página de atualizações (checagem, download),
/// itens de atualização, e o banner de ads (asserção negativa no leitor).
class ManagementSemanticsIds {
  // Settings page
  static const String settingsPageRoot = 'settings_page_root';
  static const String themeModeSelector = 'theme_mode_selector';
  static const String privacyPolicyLink = 'settings_privacy_policy_link';
  static const String termsOfUseLink = 'settings_terms_of_use_link';
  static const String appVersionInfo = 'settings_app_version_info';

  // Updates page
  static const String updatesPageRoot = 'updates_page_root';
  static const String checkForUpdatesButton = 'check_for_updates_button';
  static const String downloadOfflineButton = 'download_offline_button';

  // Updates entry — dinâmico por NR
  static String updateEntry(String nrId) => 'update_entry_$nrId';

  // Ads — validação negativa no leitor
  static const String adsPersistentBanner = 'ads_persistent_banner';

  // Badge/sino de atualizações na Home
  static const String updatesBadge = 'updates_badge';
}
