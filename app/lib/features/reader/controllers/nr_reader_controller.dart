import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_index.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/services/search_service.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/utils/user_messages.dart';
import 'package:nrfacil/features/reader/models/nr_search_hit.dart';
import 'package:nrfacil/features/reader/utils/nr_document_search.dart';
import 'package:nrfacil/features/reader/utils/reader_document_metrics.dart';
import 'package:nrfacil/features/reader/utils/reader_scroll_tracker.dart';
import 'package:nrfacil/features/reader/utils/reader_scroll_utils.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Tamanhos de fonte disponíveis no leitor (px).
const List<double> kReaderFontSizes = [14, 16, 18, 20];

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
  final fontSize = 16.0.obs;
  final isIndexOpen = false.obs;
  late final Rx<bool> _isFavorite;
  final showUpdateBanner = false.obs;

  /// Busca dentro da NR aberta
  final documentSearchQuery = ''.obs;
  final documentSearchResults = <NrSearchHit>[].obs;
  final isDocumentSearching = false.obs;
  final isSearchOpen = false.obs;

  /// Destaque ativo após selecionar um resultado
  final activeHighlightQuery = Rxn<String>();
  final highlightSectionId = Rxn<String>();
  final highlightBlockIndex = Rxn<int>();
  final currentHitIndex = 0.obs;
  final isPreambleExpanded = false.obs;

  /// Posição de leitura atual (scroll tracker)
  final currentSectionId = Rxn<String>();
  final currentItemNumber = Rxn<String>();
  final readingProgressPercent = Rxn<int>();
  final showContinueChip = false.obs;
  final showPositionIndicator = true.obs;

  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, GlobalKey> _blockKeys = {};
  final Map<String, GlobalKey> _headingKeys = {};
  final ScrollController _scrollController = ScrollController();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _initialAnchorHandled = false;
  int _searchGeneration = 0;
  Timer? _scrollSaveDebounce;
  Timer? _positionIndicatorTimer;
  double? _savedScrollPosition;

  bool get useStructuredView {
    final s = structure.value;
    return s != null && s.sections.isNotEmpty;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    _scrollController.addListener(_onScrollChanged);
    _loadReaderPreferences();
    _isFavorite = contentService.isFavorite(nrId).obs;
    _savedScrollPosition = contentService.getScrollPosition(nrId);
    await _loadNr();
    if (error.value == null) {
      showUpdateBanner.value = contentService.hasUpdate(nrId);
      contentService.recordNrOpened(nrId);
      _maybeShowContinueChip();
    }
  }

  void _maybeShowContinueChip() {
    final saved = _savedScrollPosition ?? 0;
    final hasLabel = contentService.getLastItemNumber(nrId) != null ||
        contentService.getLastHeadingViewed(nrId) != null;
    showContinueChip.value = saved > 0 && hasLabel;
  }

  void _loadReaderPreferences() {
    final storedSize = GetStorage().read<num>(StorageKeys.readerFontSize);
    if (storedSize != null) {
      fontSize.value = _migrateFontSize(storedSize.toDouble());
    }
  }

  double _migrateFontSize(double stored) {
    if (stored < 14) return 14;
    return kReaderFontSizes.reduce(
      (a, b) => (stored - a).abs() <= (stored - b).abs() ? a : b,
    );
  }

  void _persistReaderPreferences() {
    GetStorage().write(StorageKeys.readerFontSize, fontSize.value);
  }

  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (error.value != null || !_scrollController.hasClients) return;

      final saved = contentService.getReadingHistoryEntry(nrId);
      final scrollPosition = _savedScrollPosition ?? 0;
      if (scrollPosition > 0 && !showContinueChip.value) {
        final target = saved != null
            ? resolveScrollOffset(
                savedPosition: saved.scrollPosition,
                savedMaxExtent: saved.scrollMaxExtent,
                currentMaxExtent: _scrollController.position.maxScrollExtent,
              )
            : scrollPosition;
        _scrollController.jumpTo(target);
      }
      _handleInitialAnchor();
      _updateScrollPosition();
    });
  }

  void _handleInitialAnchor() {
    if (_initialAnchorHandled || initialAnchor == null || initialAnchor!.isEmpty) {
      return;
    }
    _initialAnchorHandled = true;
    navigateToSection(initialAnchor!);
  }

  void _onScrollChanged() {
    _scrollSaveDebounce?.cancel();
    _scrollSaveDebounce = Timer(
      const Duration(milliseconds: 500),
      _persistScrollState,
    );
    _updateScrollPosition();
    _showPositionIndicatorBriefly();
  }

  void _showPositionIndicatorBriefly() {
    showPositionIndicator.value = true;
    _positionIndicatorTimer?.cancel();
    _positionIndicatorTimer = Timer(const Duration(seconds: 3), () {
      if (_scrollController.hasClients &&
          _scrollController.position.pixels < 48) {
        showPositionIndicator.value = false;
      }
    });
  }

  void _updateScrollPosition() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final anchors = _buildScrollAnchors();
    final detected = findTopmostVisiblePosition(anchors: anchors);

    final s = structure.value;
    final int percent;
    if (useStructuredView &&
        s != null &&
        detected.sectionId != null &&
        detected.blockIndex != null) {
      percent = computeStructureReadingProgressPercent(
        structure: s,
        sectionId: detected.sectionId!,
        blockIndex: detected.blockIndex!,
        scrollPixels: position.pixels,
        maxScrollExtent: position.maxScrollExtent,
      );
      currentSectionId.value = detected.sectionId;
      currentItemNumber.value = detected.itemNumber;
    } else {
      percent = computeReadingProgressPercent(
        scrollPixels: position.pixels,
        maxScrollExtent: position.maxScrollExtent,
        estimatedDocumentHeight: _estimatedDocumentHeight(),
      );
      if (detected.sectionId != null) {
        currentSectionId.value = detected.sectionId;
        currentItemNumber.value = detected.itemNumber;
      }
    }
    readingProgressPercent.value = percent;
  }

  List<ReaderScrollAnchor> _buildScrollAnchors() {
    final anchors = <ReaderScrollAnchor>[];
    final s = structure.value;
    if (s == null) return anchors;

    for (final section in s.sections) {
      final hasItems = section.blocks.any(
        (b) => b is NrItemBlock && b.number.isNotEmpty,
      );

      if (!hasItems) {
        final sectionKey = _sectionKeys[section.id];
        if (sectionKey != null) {
          anchors.add(
            ReaderScrollAnchor(
              key: sectionKey,
              sectionId: section.id,
              headingLabel: _formatSectionLabel(section),
            ),
          );
        }
      }

      for (var i = 0; i < section.blocks.length; i++) {
        final block = section.blocks[i];
        final blockKey = _blockKeys['${section.id}-$i'];
        if (blockKey == null) continue;

        String? itemNumber;
        if (block is NrItemBlock && block.number.isNotEmpty) {
          itemNumber = block.number;
        }

        anchors.add(
          ReaderScrollAnchor(
            key: blockKey,
            sectionId: section.id,
            blockIndex: i,
            itemNumber: itemNumber,
            headingLabel: itemNumber ?? _formatSectionLabel(section),
          ),
        );
      }
    }

    return anchors;
  }

  void _persistScrollState() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final estimatedHeight = _estimatedDocumentHeight();
    contentService.saveScrollPosition(
      nrId,
      position.pixels,
      scrollMaxExtent: stableScrollExtent(
        maxScrollExtent: position.maxScrollExtent,
        estimatedDocumentHeight: estimatedHeight,
      ),
      lastHeadingViewed: _currentHeadingLabel(),
      lastItemNumber: currentItemNumber.value,
    );
  }

  double _estimatedDocumentHeight() {
    final s = structure.value;
    if (s == null || !useStructuredView) return 0;
    return estimateDocumentHeight(s);
  }

  String? _currentHeadingLabel() {
    if (currentItemNumber.value != null) return currentItemNumber.value;
    final s = structure.value;
    final sectionId = currentSectionId.value;
    if (s != null && sectionId != null) {
      for (final section in s.sections) {
        if (section.id == sectionId) return section.displayTitle;
      }
    }
    if (isPreambleExpanded.value) return 'Publicação e histórico';
    return highlightSectionId.value;
  }

  void continueFromSavedPosition() {
    final saved = contentService.getReadingHistoryEntry(nrId);
    final position = _savedScrollPosition ?? contentService.getScrollPosition(nrId);
    if (_scrollController.hasClients && position > 0) {
      final target = saved != null
          ? resolveScrollOffset(
              savedPosition: saved.scrollPosition,
              savedMaxExtent: saved.scrollMaxExtent,
              currentMaxExtent: _scrollController.position.maxScrollExtent,
            )
          : position;
      _scrollController.jumpTo(target);
    }
    showContinueChip.value = false;
    _updateScrollPosition();
  }

  void dismissContinueChip() => showContinueChip.value = false;

  void toggleSearch() => isSearchOpen.value = !isSearchOpen.value;

  void openSearch() => isSearchOpen.value = true;

  void closeSearch() {
    isSearchOpen.value = false;
    clearDocumentSearch();
  }

  @override
  void onClose() {
    _scrollSaveDebounce?.cancel();
    _positionIndicatorTimer?.cancel();
    _isFavorite.close();
    _persistScrollState();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.onClose();
  }

  Future<void> _loadNr() async {
    try {
      isLoading.value = true;
      error.value = null;

      final entry = contentService.manifest.value?.findNr(nrId);
      if (entry == null) {
        error.value = UserMessages.nrNotAvailable(nrId);
        return;
      }
      nrEntry.value = entry;

      final mdContent = await contentService.readNrContent(nrId);
      if (mdContent == null) {
        isDownloading.value = true;
        try {
          final ok = await contentService.downloadNrForReading(nrId);
          if (!ok) {
            error.value = contentService.lastError.value ??
                UserMessages.nrLoadRetry(nrId);
            return;
          }
        } finally {
          isDownloading.value = false;
        }

        final downloaded = await contentService.readNrContent(nrId);
        if (downloaded == null) {
          error.value = UserMessages.nrNotDownloaded(nrId);
          return;
        }
        content.value = downloaded;
      } else {
        content.value = mdContent;
        if (!contentService.isNrFullyCached(nrId)) {
          unawaited(contentService.downloadNrForReading(nrId));
        }
      }

      structure.value = await contentService.readNrStructure(nrId);
      index.value = await contentService.readNrIndex(nrId);

      AppLogger.info(
        'NR $nrId carregada (${useStructuredView ? "estruturada" : "markdown"})',
      );
    } catch (e, st) {
      AppLogger.error('Erro ao carregar NR $nrId', e, st);
      error.value = UserMessages.nrLoadFailed;
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
      if (sectionIdOrAnchor == 'preamble') {
        isPreambleExpanded.value = true;
        _scheduleScrollToTarget(sectionId: 'preamble', blockIndex: 0);
        isIndexOpen.value = false;
        return;
      }

      final sectionId =
          _resolveSectionId(sectionIdOrAnchor) ?? sectionIdOrAnchor;
      _scheduleScrollToTarget(sectionId: sectionId, blockIndex: -1);
    } else {
      navigateToHeading(sectionIdOrAnchor);
    }
    isIndexOpen.value = false;
  }

  void _scheduleScrollToTarget({
    required String sectionId,
    required int blockIndex,
  }) {
    void tryScroll(int attempt) {
      if (attempt == 0) {
        _jumpToEstimatedOffset(sectionId: sectionId, blockIndex: blockIndex);
      } else {
        _nudgeLazyListScroll(
          sectionId: sectionId,
          blockIndex: blockIndex,
          attempt: attempt,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tryScrollToTarget(sectionId: sectionId, blockIndex: blockIndex)) {
          _updateScrollPosition();
          return;
        }
        if (attempt >= 48) {
          AppLogger.warning(
            'Não foi possível rolar até $sectionId'
            '${blockIndex >= 0 ? ' bloco $blockIndex' : ''}',
          );
          return;
        }
        tryScroll(attempt + 1);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryScroll(0);
    });
  }

  double? _estimatedScrollOffset({
    required String sectionId,
    int blockIndex = -1,
  }) {
    if (!useStructuredView) return null;

    if (sectionId == 'preamble' || sectionId == 'meta') return 0;

    final s = structure.value;
    if (s == null) return null;

    final sectionIndex = s.sections.indexWhere((sec) => sec.id == sectionId);
    if (sectionIndex < 0) return null;

    return estimateProgressOffset(
      structure: s,
      sectionId: sectionId,
      blockIndex: blockIndex,
    );
  }

  void _jumpToEstimatedOffset({
    required String sectionId,
    required int blockIndex,
  }) {
    if (!_scrollController.hasClients || !useStructuredView) return;

    final offset = _estimatedScrollOffset(
      sectionId: sectionId,
      blockIndex: blockIndex,
    );
    if (offset == null) return;

    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(offset.clamp(0.0, max));
  }

  void _nudgeLazyListScroll({
    required String sectionId,
    required int blockIndex,
    required int attempt,
  }) {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final estimated = _estimatedScrollOffset(
      sectionId: sectionId,
      blockIndex: blockIndex,
    );

    if (estimated != null && estimated > position.pixels + 24) {
      final target = estimated.clamp(0.0, position.maxScrollExtent);
      position.jumpTo(target);
      return;
    }

    if (attempt % 4 == 0 && estimated != null) {
      position.jumpTo(estimated.clamp(0.0, position.maxScrollExtent));
      return;
    }

    final step = 480.0 + (attempt * 80.0);
    position.jumpTo(
      (position.pixels + step).clamp(0.0, position.maxScrollExtent),
    );
  }

  bool _scrollToKey(GlobalKey? key, {double alignment = 0.08}) {
    if (key == null) return false;
    return scrollToWidgetKey(
      key: key,
      scrollController: _scrollController,
      alignment: alignment,
    );
  }

  bool _tryScrollToTarget({
    required String sectionId,
    required int blockIndex,
  }) {
    if (!useStructuredView) return false;

    if (sectionId == 'meta') {
      if (!_scrollController.hasClients) return false;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      return true;
    }

    if (sectionId == 'preamble') {
      isPreambleExpanded.value = true;
      return _scrollToKey(_blockKeys['preamble-0']);
    }

    if (blockIndex >= 0) {
      final blockKey = _blockKeys['$sectionId-$blockIndex'];
      if (_scrollToKey(blockKey)) {
        return true;
      }
    }

    final sectionKey = _sectionKeys[sectionId];
    return _scrollToKey(sectionKey, alignment: 0.05);
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
    final idx = kReaderFontSizes.indexOf(fontSize.value);
    if (idx < 0 || idx >= kReaderFontSizes.length - 1) return;
    fontSize.value = kReaderFontSizes[idx + 1];
    _persistReaderPreferences();
  }

  void decreaseFontSize() {
    final idx = kReaderFontSizes.indexOf(fontSize.value);
    if (idx <= 0) return;
    fontSize.value = kReaderFontSizes[idx - 1];
    _persistReaderPreferences();
  }

  void toggleDarkMode() {
    Get.find<ThemeController>().toggleDarkMode();
  }

  void toggleIndex() => isIndexOpen.value = !isIndexOpen.value;

  void setPreambleExpanded(bool value) => isPreambleExpanded.value = value;

  void navigateToItemNumber(String itemNumber) {
    final normalized = itemNumber.trim();
    if (normalized.isEmpty) return;

    final s = structure.value;
    if (s != null) {
      for (final section in s.sections) {
        for (var i = 0; i < section.blocks.length; i++) {
          final block = section.blocks[i];
          if (block is NrItemBlock && block.number.trim() == normalized) {
            highlightSectionId.value = section.id;
            highlightBlockIndex.value = i;
            currentSectionId.value = section.id;
            currentItemNumber.value = normalized;
            _scheduleScrollToTarget(sectionId: section.id, blockIndex: i);
            isIndexOpen.value = false;
            return;
          }
        }
      }
    }

    navigateToSection(normalized);
  }

  final isDownloading = false.obs;

  Future<void> downloadNrContent() async {
    isDownloading.value = true;
    try {
      final ok = await contentService.downloadNrIfNeeded(nrId);
      if (ok) {
        await _loadNr();
      } else if (contentService.lastError.value != null) {
        error.value = contentService.lastError.value;
      }
    } finally {
      isDownloading.value = false;
    }
  }

  ScrollController get scrollController => _scrollController;
  bool get isFavorite => _isFavorite.value;

  String? get continueLabel {
    final item = contentService.getLastItemNumber(nrId);
    if (item != null) return 'item $item';
    final heading = contentService.getLastHeadingViewed(nrId);
    if (heading != null) return heading;
    return null;
  }

  /// Label amigável para o indicador de posição (nunca slug interno).
  String? get currentPositionLabel {
    if (currentItemNumber.value != null) return currentItemNumber.value;
    final s = structure.value;
    final sectionId = currentSectionId.value;
    if (s == null || sectionId == null) return null;
    for (final section in s.sections) {
      if (section.id == sectionId) {
        return _formatSectionLabel(section);
      }
    }
    return null;
  }

  String _formatSectionLabel(NrSection section) {
    final title = stripInlineMarkup(section.title);
    if (section.number.isEmpty) {
      return stripInlineMarkup(section.displayTitle);
    }
    if (title.isEmpty) return section.number;
    return '${section.number} $title';
  }

  void toggleFavorite() {
    contentService.toggleFavorite(nrId);
    _isFavorite.value = contentService.isFavorite(nrId);
  }

  void dismissUpdateBanner() {
    showUpdateBanner.value = false;
    contentService.markNrAsSeen(nrId);
  }

  UpdateEntry? getUpdateEntry() => contentService.updateEntryFor(nrId);

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
      currentHitIndex.value = 0;
      activeHighlightQuery.value = trimmed;

      if (results.isNotEmpty) {
        _expandPreambleForHits(results);
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

  void _expandPreambleForHits(List<NrSearchHit> hits) {
    for (final hit in hits) {
      if (hit.sectionId == 'preamble') {
        isPreambleExpanded.value = true;
        break;
      }
    }
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
    }

    _scheduleScrollToHit(hit);
  }

  void _scheduleScrollToHit(NrSearchHit hit) {
    void tryScroll(int attempt) {
      if (attempt == 0) {
        _jumpToEstimatedOffset(
          sectionId: hit.sectionId,
          blockIndex: hit.blockIndex,
        );
      } else {
        _nudgeLazyListScroll(
          sectionId: hit.sectionId,
          blockIndex: hit.blockIndex,
          attempt: attempt,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tryScrollToHit(hit)) {
          _updateScrollPosition();
          return;
        }
        if (attempt >= 48) return;
        tryScroll(attempt + 1);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryScroll(0);
    });
  }

  bool _tryScrollToHit(NrSearchHit hit) {
    if (!useStructuredView) {
      return _tryScrollToMarkdownHit(hit);
    }

    if (hit.blockIndex >= 0) {
      final blockKey = _blockKeys['${hit.sectionId}-${hit.blockIndex}'];
      final plainText = _plainTextForHit(hit);
      if (blockKey?.currentContext != null && plainText != null) {
        if (hit.matchStart > 0) {
          final scrolled = scrollToSearchMatch(
            context: blockKey!.currentContext!,
            scrollController: _scrollController,
            matchStart: hit.matchStart,
            plainText: plainText,
            fontSize: fontSize.value,
          );
          if (scrolled) {
            return true;
          }
        }
        return _scrollToKey(blockKey);
      }
    }

    return _tryScrollToTarget(
      sectionId: hit.sectionId,
      blockIndex: hit.blockIndex,
    );
  }

  bool _tryScrollToMarkdownHit(NrSearchHit hit) {
    for (final candidate in [hit.label, hit.sectionId]) {
      final key = _headingKeys[_normalizeKey(candidate)];
      if (key?.currentContext != null) {
        return scrollToSearchMatch(
          context: key!.currentContext!,
          scrollController: _scrollController,
          matchStart: 0,
          plainText: hit.label,
          fontSize: fontSize.value + 2,
        );
      }
    }
    return false;
  }

  String? _plainTextForHit(NrSearchHit hit) {
    final s = structure.value;
    if (s == null) return null;

    if (hit.sectionId == 'meta') {
      return stripInlineMarkup(s.title);
    }

    if (hit.sectionId == 'preamble') {
      if (hit.blockIndex < 0 || hit.blockIndex >= s.preamble.blocks.length) {
        return null;
      }
      return stripInlineMarkup(nrBlockPlainText(s.preamble.blocks[hit.blockIndex]));
    }

    NrSection? section;
    for (final sec in s.sections) {
      if (sec.id == hit.sectionId) {
        section = sec;
        break;
      }
    }
    if (section == null) return null;

    if (hit.blockIndex < 0) {
      return stripInlineMarkup(section.displayTitle);
    }
    if (hit.blockIndex >= section.blocks.length) return null;
    return stripInlineMarkup(nrBlockPlainText(section.blocks[hit.blockIndex]));
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
