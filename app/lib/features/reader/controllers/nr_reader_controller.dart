import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_index.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/services/search_service.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/reader/models/nr_search_hit.dart';
import 'package:nrfacil/features/reader/utils/nr_document_search.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Controller para o NRReaderPage — gerencia estado do leitor de uma NR.
class NRReaderController extends GetxController {
  final String nrId;
  final String? initialAnchor;
  final ContentService contentService;
  final SearchService? searchService;

  NRReaderController({
    required this.nrId,
    this.initialAnchor,
    required this.contentService,
    this.searchService,
  });
  /// Conteúdo Markdown da NR (fallback)
  final content = Rxn<String>();

  /// Estrutura semântica (structure.json)
  final structure = Rxn<NrStructure>();

  /// Índice de navegação legado (index.json)
  final index = Rxn<NrIndex>();

  /// Metadados da NR (do manifest)
  final nrEntry = Rxn<ManifestEntry>();

  final isLoading = true.obs;
  final error = Rxn<String>();
  final fontSize = 14.0.obs;
  final isDarkMode = false.obs;
  final isIndexOpen = false.obs;
  late final Rx<bool> _isFavorite;
  final showUpdateBanner = false.obs;

  /// Busca dentro da NR aberta
  final documentSearchQuery = ''.obs;
  final documentSearchResults = <NrSearchHit>[].obs;
  final isDocumentSearching = false.obs;

  /// Destaque ativo após selecionar um resultado
  final activeHighlightQuery = Rxn<String>();
  final highlightSectionId = Rxn<String>();
  final highlightBlockIndex = Rxn<int>();
  final currentHitIndex = 0.obs;
  final isPreambleExpanded = false.obs;

  /// Seções expandidas no leitor estruturado
  final expandedSectionIds = <String>{}.obs;

  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _blockKeys = {};
  final Map<String, GlobalKey> _headingKeys = {};
  final ScrollController _scrollController = ScrollController();
  bool _initialAnchorHandled = false;
  int _searchGeneration = 0;

  bool get useStructuredView {
    final s = structure.value;
    return s != null && s.sections.isNotEmpty;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    _isFavorite = contentService.isFavorite(nrId).obs;
    await _loadNr();
    if (error.value == null) {
      showUpdateBanner.value = contentService.hasUpdate(nrId);
      GetStorage().write(StorageKeys.lastOpenedNr, nrId);
      contentService.addToReadingHistory(nrId);
    }
  }

  @override
  void onReady() {
    super.onReady();
    Future.microtask(() {
      if (error.value == null && _scrollController.hasClients) {
        final scrollPosition = contentService.getScrollPosition(nrId);
        if (scrollPosition > 0) {
          _scrollController.jumpTo(scrollPosition);
        }
      }
      _handleInitialAnchor();
    });
  }

  void _handleInitialAnchor() {
    if (_initialAnchorHandled || initialAnchor == null || initialAnchor!.isEmpty) {
      return;
    }
    _initialAnchorHandled = true;
    navigateToSection(initialAnchor!);
  }

  @override
  void onClose() {
    _isFavorite.close();
    if (_scrollController.hasClients) {
      contentService.saveScrollPosition(nrId, _scrollController.offset);
    }
    _scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadNr() async {
    try {
      isLoading.value = true;
      error.value = null;

      final entry = contentService.manifest.value?.findNr(nrId);
      if (entry == null) {
        error.value = 'NR $nrId não encontrada no manifest';
        return;
      }
      nrEntry.value = entry;

      final mdContent = await contentService.readNrContent(nrId);
      if (mdContent == null) {
        error.value =
            'Conteúdo de $nrId não encontrado em cache. Sincronize antes.';
        return;
      }
      content.value = mdContent;

      structure.value = await contentService.readNrStructure(nrId);
      index.value = await contentService.readNrIndex(nrId);

      AppLogger.info(
        'NR $nrId carregada (${useStructuredView ? "estruturada" : "markdown"})',
      );
    } catch (e, st) {
      AppLogger.error('Erro ao carregar NR $nrId', e, st);
      error.value = 'Erro ao carregar NR: $e';
    } finally {
      isLoading.value = false;
    }
  }

  GlobalKey sectionKeyFor(String sectionId) {
    return _sectionKeys.putIfAbsent(sectionId, GlobalKey.new);
  }

  GlobalKey blockKeyFor(String sectionId, int blockIndex) {
    return _blockKeys.putIfAbsent(
      '$sectionId-$blockIndex',
      GlobalKey.new,
    );
  }

  void registerHeadingKey(String headingText, GlobalKey key) {
    _headingKeys[_normalizeKey(headingText)] = key;
  }

  void navigateToSection(String sectionIdOrAnchor) {
    if (useStructuredView) {
      final sectionId = _resolveSectionId(sectionIdOrAnchor) ?? sectionIdOrAnchor;
      if (sectionId.isNotEmpty) {
        expandSection(sectionId);
      }
      final key = _sectionKeys[sectionId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Seção ainda não montada (lazy), tenta após frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final retryKey = _sectionKeys[sectionId];
          if (retryKey?.currentContext != null) {
            Scrollable.ensureVisible(
              retryKey!.currentContext!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            AppLogger.warning('Seção não encontrada: $sectionIdOrAnchor');
          }
        });
      }
    } else {
      navigateToHeading(sectionIdOrAnchor);
    }
    isIndexOpen.value = false;
  }

  void navigateToHeading(String headingText) {
    final key = _headingKeys[_normalizeKey(headingText)];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      AppLogger.warning('Heading não encontrado: $headingText');
    }
    isIndexOpen.value = false;
  }

  String? _resolveSectionId(String anchor) {
    final s = structure.value;
    if (s == null) return null;

    final normalized = _normalizeKey(anchor);

    for (final section in s.sections) {
      if (_normalizeKey(section.id) == normalized) return section.id;
      if (_normalizeKey(section.displayTitle) == normalized) return section.id;
      if (_normalizeKey(section.number) == normalized) return section.id;
      if (_normalizeKey('**${section.number} ${section.title}**') ==
          normalized) {
        return section.id;
      }
    }

    // Match parcial pelo texto do heading de busca
    for (final section in s.sections) {
      final cleanTitle = _normalizeKey(stripInlineMarkup(section.displayTitle));
      if (cleanTitle.contains(normalized) || normalized.contains(cleanTitle)) {
        return section.id;
      }
    }

    return null;
  }

  String _normalizeKey(String text) {
    return stripInlineMarkup(text).toLowerCase().trim();
  }

  void increaseFontSize() {
    if (fontSize.value < 20) fontSize.value += 2;
  }

  void decreaseFontSize() {
    if (fontSize.value > 12) fontSize.value -= 2;
  }

  void toggleDarkMode() => isDarkMode.value = !isDarkMode.value;
  void toggleIndex() => isIndexOpen.value = !isIndexOpen.value;

  ScrollController get scrollController => _scrollController;
  bool get isFavorite => _isFavorite.value;

  void toggleFavorite() {
    contentService.toggleFavorite(nrId);
    _isFavorite.value = contentService.isFavorite(nrId);
  }

  void dismissUpdateBanner() {
    showUpdateBanner.value = false;
    contentService.markNrAsSeen(nrId);
  }

  UpdateEntry? getUpdateEntry() => contentService.updateEntryFor(nrId);

  bool isSectionExpanded(String sectionId) =>
      expandedSectionIds.contains(sectionId);

  void toggleSectionExpanded(String sectionId) {
    if (expandedSectionIds.contains(sectionId)) {
      expandedSectionIds.remove(sectionId);
    } else {
      expandedSectionIds.add(sectionId);
    }
    expandedSectionIds.refresh();
  }

  void expandSection(String sectionId) {
    if (!expandedSectionIds.contains(sectionId)) {
      expandedSectionIds.add(sectionId);
      expandedSectionIds.refresh();
    }
  }

  Future<void> searchInDocument(String query) async {
    documentSearchQuery.value = query;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      clearDocumentSearch();
      return;
    }

    final generation = ++_searchGeneration;
    isDocumentSearching.value = true;
    try {
      final results = <NrSearchHit>[];

      final s = structure.value;
      if (s != null) {
        results.addAll(searchInNrDocument(s, trimmed));
      }

      if (results.isEmpty) {
        results.addAll(await _searchViaIndexAsHits(trimmed));
      }

      if (results.isEmpty && content.value != null) {
        results.addAll(
          searchInMarkdownContent(content.value!, s, trimmed),
        );
      }

      if (generation != _searchGeneration) return;

      _setDocumentSearchResults(results);
      _expandSectionsForHits(results);
      currentHitIndex.value = 0;

      activeHighlightQuery.value = trimmed;

      if (results.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (generation == _searchGeneration) {
            goToSearchHit(results.first);
          }
        });
      } else {
        highlightSectionId.value = null;
        highlightBlockIndex.value = null;
      }
    } finally {
      if (generation == _searchGeneration) {
        isDocumentSearching.value = false;
      }
    }
  }

  void _setDocumentSearchResults(List<NrSearchHit> results) {
    documentSearchResults
      ..clear()
      ..addAll(results);
    documentSearchResults.refresh();
  }

  int get matchCount => documentSearchResults.length;

  void goToNextHit() {
    if (documentSearchResults.isEmpty) return;
    final next = (currentHitIndex.value + 1) % documentSearchResults.length;
    currentHitIndex.value = next;
    goToSearchHit(documentSearchResults[next]);
  }

  void goToPreviousHit() {
    if (documentSearchResults.isEmpty) return;
    currentHitIndex.value =
        (currentHitIndex.value - 1 + documentSearchResults.length) %
            documentSearchResults.length;
    goToSearchHit(documentSearchResults[currentHitIndex.value]);
  }

  void _expandSectionsForHits(List<NrSearchHit> hits) {
    var hasPreamble = false;
    for (final hit in hits) {
      if (hit.sectionId == 'preamble') {
        hasPreamble = true;
      } else if (hit.sectionId != 'meta') {
        expandSection(hit.sectionId);
      }
    }
    isPreambleExpanded.value = hasPreamble;
  }

  Future<List<NrSearchHit>> _searchViaIndexAsHits(String trimmed) async {
    final chunks = await contentService.readSearchIndex(nrId);
    final normalized = normalizeForSearch(trimmed);
    final queryLength = normalized.length;
    final hits = <NrSearchHit>[];

    for (final chunk in chunks) {
      final clean = stripInlineMarkup(chunk.text);
      if (clean.isEmpty) continue;

      final sectionId = _resolveSectionId(chunk.heading) ?? chunk.heading;
      final blockIndex = _resolveBlockIndexForHit(
        sectionId: sectionId,
        query: trimmed,
        chunkText: chunk.text,
      );
      final label = stripInlineMarkup(chunk.heading);

      for (final offset in findOccurrenceOffsets(clean, trimmed)) {
        hits.add(
          NrSearchHit(
            sectionId: sectionId,
            blockIndex: blockIndex,
            matchStart: offset,
            label: label,
            snippet: searchSnippetAt(
              clean,
              offset: offset,
              queryLength: queryLength,
            ),
          ),
        );
      }
    }
    return hits;
  }

  void clearDocumentSearch() {
    documentSearchQuery.value = '';
    _setDocumentSearchResults([]);
    currentHitIndex.value = 0;
    isPreambleExpanded.value = false;
    clearHighlight();
  }

  void clearHighlight() {
    activeHighlightQuery.value = null;
    highlightSectionId.value = null;
    highlightBlockIndex.value = null;
  }

  void goToSearchHit(NrSearchHit hit) {
    final query = documentSearchQuery.value.trim();
    activeHighlightQuery.value = query.isNotEmpty ? query : null;
    highlightSectionId.value = hit.sectionId;
    highlightBlockIndex.value = hit.blockIndex;

    if (hit.sectionId == 'preamble') {
      isPreambleExpanded.value = true;
    } else if (hit.sectionId != 'meta') {
      expandSection(hit.sectionId);
      expandedSectionIds.refresh();
    }

    _scheduleScrollToHit(hit);
  }

  void _scheduleScrollToHit(NrSearchHit hit) {
    if (useStructuredView) {
      _preScrollForStructuredHit(hit);
    }

    void tryScroll(int attempt) {
      if (_tryScrollToHit(hit) || attempt >= 12) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tryScroll(attempt + 1);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryScroll(0);
    });
  }

  void _preScrollForStructuredHit(NrSearchHit hit) {
    if (!_scrollController.hasClients) return;

    if (hit.sectionId == 'meta' || hit.sectionId == 'preamble') {
      _scrollController.jumpTo(0);
      return;
    }

    final s = structure.value;
    if (s == null) return;

    final index = s.sections.indexWhere((sec) => sec.id == hit.sectionId);
    if (index < 0) return;

    const headerEstimate = 320.0;
    final sectionHeight =
        expandedSectionIds.contains(hit.sectionId) ? 280.0 : 80.0;
    final offset = headerEstimate + index * sectionHeight;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(offset.clamp(0.0, max));
  }

  bool _tryScrollToHit(NrSearchHit hit) {
    if (!useStructuredView) {
      return _tryScrollToMarkdownHit(hit);
    }

    if (hit.sectionId == 'meta') {
      if (!_scrollController.hasClients) return false;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return true;
    }

    if (hit.blockIndex >= 0) {
      final blockKey = _blockKeys['${hit.sectionId}-${hit.blockIndex}'];
      if (blockKey?.currentContext != null) {
        Scrollable.ensureVisible(
          blockKey!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
        return true;
      }
    }

    final sectionKey = _sectionKeys[hit.sectionId];
    if (sectionKey?.currentContext != null) {
      Scrollable.ensureVisible(
        sectionKey!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
      return true;
    }

    return false;
  }

  bool _tryScrollToMarkdownHit(NrSearchHit hit) {
    for (final candidate in [hit.label, hit.sectionId]) {
      final key = _headingKeys[_normalizeKey(candidate)];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
        return true;
      }
    }
    return false;
  }

  int _resolveBlockIndexForHit({
    required String sectionId,
    required String query,
    required String chunkText,
  }) {
    final s = structure.value;
    if (s == null) return 0;

    NrSection? section;
    for (final sec in s.sections) {
      if (sec.id == sectionId) {
        section = sec;
        break;
      }
    }
    if (section == null) return 0;

    final normQuery = normalizeForSearch(query);
    final normChunk = normalizeForSearch(chunkText);

    for (var i = 0; i < section.blocks.length; i++) {
      final blockText = nrBlockPlainText(section.blocks[i]);
      final normBlock = normalizeForSearch(blockText);
      if (normBlock.contains(normQuery) || normBlock.contains(normChunk)) {
        return i;
      }
    }

    return 0;
  }
}
