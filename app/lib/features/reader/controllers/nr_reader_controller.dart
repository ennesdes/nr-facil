import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_index.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/utils/app_logger.dart';

/// Controller para o NRReaderPage — gerencia estado do leitor de uma NR.
///
/// Responsabilidades:
/// - Carregar conteúdo Markdown da NR
/// - Carregar índice de navegação (headings)
/// - Gerenciar preferências de exibição (tamanho de fonte, modo escuro)
/// - Estado do painel de índice (aberto/fechado)
/// - Chamar markNrAsSeen ao abrir
///
/// Uso: GetView com NRReaderController
class NRReaderController extends GetxController {
  final String nrId;
  final ContentService _contentService;

  NRReaderController({
    required this.nrId,
    required this._contentService,
  });

  /// Conteúdo Markdown da NR
  final content = Rxn<String>();

  /// Índice de navegação (headings)
  final index = Rxn<NrIndex>();

  /// Metadados da NR (do manifest)
  final nrEntry = Rxn<ManifestEntry>();

  /// Estado de carregamento
  final isLoading = true.obs;

  /// Mensagem de erro (null = sucesso)
  final error = Rxn<String>();

  /// Tamanho da fonte de exibição (em dp, base 14)
  /// Valores: 12, 14, 16, 18, 20
  final fontSize = 14.0.obs;

  /// Modo escuro ativado
  final isDarkMode = false.obs;

  /// Painel de índice aberto
  final isIndexOpen = false.obs;

  /// NR é favorita
  late final Rx<bool> _isFavorite;

  @override
  Future<void> onInit() async {
    super.onInit();

    // Inicializar estado de favorito
    _isFavorite = _contentService.isFavorite(nrId).obs;

    await _loadNr();
    // Marcar NR como vista após carregamento bem-sucedido
    if (error.value == null) {
      _contentService.markNrAsSeen(nrId);
      // Gravar como última NR aberta
      GetStorage().write(StorageKeys.lastOpenedNr, nrId);
    }
  }

  @override
  void onClose() {
    _isFavorite.close();
    super.onClose();
  }

  /// Carregar conteúdo e índice da NR.
  Future<void> _loadNr() async {
    try {
      isLoading.value = true;
      error.value = null;

      // Obter metadados do manifest
      final entry = _contentService.manifest.value?.findNr(nrId);
      if (entry == null) {
        error.value = 'NR $nrId não encontrada no manifest';
        return;
      }
      nrEntry.value = entry;

      // Carregar conteúdo Markdown
      final mdContent = await _contentService.readNrContent(nrId);
      if (mdContent == null) {
        error.value = 'Conteúdo de $nrId não encontrado em cache. Sincronize antes.';
        return;
      }
      content.value = mdContent;

      // Carregar índice de navegação
      final nrIndex = await _contentService.readNrIndex(nrId);
      index.value = nrIndex;

      AppLogger.info('NR $nrId carregada com sucesso');
    } catch (e, st) {
      AppLogger.error('Erro ao carregar NR $nrId', e, st);
      error.value = 'Erro ao carregar NR: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Aumentar tamanho da fonte.
  void increaseFontSize() {
    if (fontSize.value < 20) {
      fontSize.value += 2;
    }
  }

  /// Diminuir tamanho da fonte.
  void decreaseFontSize() {
    if (fontSize.value > 12) {
      fontSize.value -= 2;
    }
  }

  /// Alternar modo escuro.
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
  }

  /// Abrir/fechar painel de índice.
  void toggleIndex() {
    isIndexOpen.value = !isIndexOpen.value;
  }

  /// Navegar para um heading do índice.
  /// (Será implementado na View — scroll_controller ou similar)
  void navigateToHeading(String headingId) {
    AppLogger.debug('Navegando para heading: $headingId');
    // Fechar índice após navegação
    isIndexOpen.value = false;
  }

  /// Verificar se esta NR é favorita.
  bool get isFavorite => _isFavorite.value;

  /// Adicionar/remover esta NR dos favoritos.
  void toggleFavorite() {
    _contentService.toggleFavorite(nrId);
    _isFavorite.value = _contentService.isFavorite(nrId);
  }
}
