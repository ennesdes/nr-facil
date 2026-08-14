/// Configurações centralizadas da aplicação.
///
/// URLs e endpoints nunca devem estar hardcoded na lógica — tudo aqui.
class AppConfig {
  // GitHub raw URLs — fonte da verdade
  // Em futuro, isso pode vir de um arquivo .env, mas por enquanto é constante aqui
  static const String githubRawBaseUrl =
      'https://raw.githubusercontent.com/douglasennes/nr-facil/main';

  /// URL remota do manifest.json (índice de todas as NRs).
  /// Configurável aqui para facilitar testes e futura migração de repositório.
  static const String manifestUrl = '$githubRawBaseUrl/manifest.json';

  /// URL base para download de conteúdo das NRs (content/nr-XX/...).
  static const String contentBaseUrl = '$githubRawBaseUrl/content';

  /// Tempo máximo de espera para sync (em segundos).
  static const int syncTimeoutSeconds = 30;

  /// Número máximo de tentativas de download para um arquivo.
  static const int maxRetries = 3;

  /// Intervalo entre tentativas de download (em segundos).
  static const int retryDelaySeconds = 2;
}
