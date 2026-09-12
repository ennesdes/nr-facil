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

  /// URL raw de um asset versionado (PNG de tabela, etc.) em um ref git.
  static String contentAssetUrl(
    String nrId,
    String assetPath, {
    String gitRef = 'main',
  }) {
    final normalized = assetPath.replaceFirst(RegExp(r'^\.\./'), '');
    const repoRoot = 'https://raw.githubusercontent.com/ennesdes/nr-facil';
    return '$repoRoot/$gitRef/content/$nrId/$normalized';
  }

  /// Tempo máximo de espera para sync (em segundos).
  static const int syncTimeoutSeconds = 30;

  /// Número máximo de tentativas de download para um arquivo.
  static const int maxRetries = 3;

  /// Intervalo entre tentativas de download (em segundos).
  static const int retryDelaySeconds = 2;

  /// AdMob — IDs de teste do Google em dev local.
  /// Em release (CI ou build local), injetar via --dart-define / GitHub Secrets.
  /// Ver docs/procedures/05-configurar-admob.md e docs/CI_SETUP.md
  static const String _admobTestAppId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String _admobTestBannerUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _admobTestInterstitialUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// App ID (AndroidManifest usa env ADMOB_APP_ID no build de release).
  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: _admobTestAppId,
  );

  static const String admobBannerListUnitId = String.fromEnvironment(
    'ADMOB_BANNER_UNIT_ID',
    defaultValue: _admobTestBannerUnitId,
  );

  /// Interstitial (vídeo/tela cheia).
  static const String admobInterstitialUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_UNIT_ID',
    defaultValue: _admobTestInterstitialUnitId,
  );

  /// Intervalo mínimo entre interstitials (minutos).
  static const int interstitialCooldownMinutes = 15;

  /// Tempo mínimo de sessão antes do primeiro interstitial (minutos).
  static const int interstitialMinSessionMinutes = 2;

  /// Teto de interstitials por hora de uso ativo.
  static const int interstitialMaxPerHour = 6;

  /// Habilitar anúncios (banner na Home; interstitial ao sair do leitor).
  static const bool adsEnabled = true;

  /// Política de privacidade (site Solve Better). Ver docs/procedures/08-github-pages-privacidade.md
  static const String privacyPolicyUrl =
      'https://solvebetter.com.br/apps/nr-facil/privacidade/';

  /// Termos de uso (site Solve Better).
  static const String termsOfUseUrl =
      'https://solvebetter.com.br/apps/nr-facil/termos/';
}
