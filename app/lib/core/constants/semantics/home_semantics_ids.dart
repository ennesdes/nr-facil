/// Constantes de Semantics ID para telas e widgets do bloco Navegação.
///
/// Convenção: cada propriedade é um identificador estável para automação Maestro.
/// Para IDs dinâmicos (por exemplo, por nrId), use métodos estáticos que retornam o literal construído.
class HomeSemanticsIds {
  // === Bottom Navigation ===
  /// ID do item "Normas" da bottom nav bar.
  static const String normasTab = 'normas_tab';

  /// ID do item "Favoritos" da bottom nav bar.
  static const String favoritosTab = 'favoritos_tab';

  /// ID do item "Buscar" da bottom nav bar.
  static const String buscarTab = 'buscar_tab';

  // === App Bar Actions ===
  /// ID do ícone de sino (notificações/atualizações) na AppBar.
  static const String notificationsBell = 'notifications_bell';

  /// ID do ícone de configurações (settings) na AppBar.
  static const String settingsButton = 'settings_button';

  // === NR List Tiles ===
  /// ID do tile de uma NR na lista (Normas ou Favoritos).
  /// Uso: `Semantics(identifier: HomeSemanticsIds.nrTile(nrId), ...)`
  static String nrTile(String nrId) => 'nr_tile_$nrId';

  /// ID do botão de favoritar/desfavoritar dentro de um NR tile.
  /// Uso: `Semantics(identifier: HomeSemanticsIds.favoriteToggle(nrId), ...)`
  static String favoriteToggle(String nrId) => 'favorite_toggle_$nrId';

  // === Empty States ===
  /// ID do estado vazio da aba Favoritos.
  static const String emptyFavoritosState = 'empty_favoritos_state';

  /// ID do estado vazio da aba Normas.
  static const String emptyNormasState = 'empty_normas_state';

  // === Search ===
  /// ID do campo de busca full-text na aba Buscar.
  static const String searchField = 'search_field';

  /// ID do tile de resultado de busca na lista de resultados.
  /// Uso: `Semantics(identifier: HomeSemanticsIds.searchResultTile(nrId), ...)`
  static String searchResultTile(String nrId) => 'search_result_$nrId';
}
