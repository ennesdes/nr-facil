/// Configurações centralizadas da aplicação.
///
/// URLs e endpoints nunca devem estar hardcoded na lógica — tudo aqui.
class AppConfig {
  // GitHub raw URLs — fonte da verdade
  // Em futuro, isso pode vir de um arquivo .env, mas por enquanto é constante aqui
  static const String githubRawBaseUrl =
      'https://raw.githubusercontent.com/ennesdes/nr-facil/main';

  /// URL remota do manifest.json (índice de todas as NRs).
  /// Configurável aqui para facilitar testes e futura migração de repositório.
  static const String manifestUrl = '$githubRawBaseUrl/manifest.json';

  /// URL remota do app_meta.json (feed de atualizações e versão mínima).
  /// Mesmo padrão que manifestUrl — centralizado aqui para facilitar testes.
  static const String appMetaUrl = '$githubRawBaseUrl/app_meta.json';

  /// URL base para download de conteúdo das NRs (content/nr-XX/...).
  static const String contentBaseUrl = '$githubRawBaseUrl/content';

  /// Tempo máximo de espera para sync (em segundos).
  static const int syncTimeoutSeconds = 30;

  /// Número máximo de tentativas de download para um arquivo.
  static const int maxRetries = 3;

  /// Intervalo entre tentativas de download (em segundos).
  static const int retryDelaySeconds = 2;

  /// AdMob — IDs de teste do Google (substituir em produção).
  /// Ver docs/procedures/05-configurar-admob.md
  static const String admobAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String admobBannerListUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  /// Habilitar banners em listas (Favoritos/Todos/Busca). Nunca no leitor.
  static const bool adsEnabled = true;
}
