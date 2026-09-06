import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/models/reading_history_entry.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentService — histórico de leitura', () {
    late ContentService contentService;

    setUpAll(() async {
      final storageDir = await Directory.systemTemp.createTemp('nr_reading_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(
        storageDir.path,
      );
      await GetStorage.init();
    });

    setUp(() async {
      Get.testMode = true;
      GetStorage().erase();
      contentService = ContentService();
      await contentService.onInit();
    });

    tearDown(() {
      contentService.onClose();
      Get.reset();
    });

    test('recordNrOpened atualiza lastOpenedNrId reativo', () {
      expect(contentService.lastOpenedNrId.value, isNull);

      contentService.recordNrOpened('nr-06');

      expect(contentService.lastOpenedNrId.value, 'nr-06');
      expect(GetStorage().read<String>(StorageKeys.lastOpenedNr), 'nr-06');
    });

    test('reabrir NR preserva progresso salvo', () {
      contentService.saveScrollPosition(
        'nr-06',
        800,
        scrollMaxExtent: 1000,
        lastHeadingViewed: '6.1 Objetivo',
        lastItemNumber: '6.1.1',
      );

      contentService.recordNrOpened('nr-06');

      final entry = contentService.getReadingHistoryEntry('nr-06');
      expect(entry?.scrollPosition, 800);
      expect(entry?.scrollMaxExtent, 1000);
      expect(entry?.lastHeadingViewed, '6.1 Objetivo');
      expect(entry?.lastItemNumber, '6.1.1');
      expect(contentService.getReadingProgressPercent('nr-06'), 80);
    });

    test('abrir outra NR atualiza lastOpenedNrId', () {
      contentService.recordNrOpened('nr-06');
      contentService.recordNrOpened('nr-10');

      expect(contentService.lastOpenedNrId.value, 'nr-10');
      expect(contentService.getReadingHistoryEntry('nr-06'), isNotNull);
      expect(contentService.getReadingHistoryEntry('nr-10'), isNotNull);
    });

    test('saveScrollPosition incrementa readingHistoryVersion', () {
      final before = contentService.readingHistoryVersion.value;

      contentService.saveScrollPosition('nr-06', 1000, scrollMaxExtent: 1000);

      expect(contentService.readingHistoryVersion.value, before + 1);
      expect(contentService.getReadingProgressPercent('nr-06'), 100);
    });

    test('ReadingHistoryEntry effectiveProgressPercent no final do scroll', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2026),
        scrollPosition: 999.5,
        scrollMaxExtent: 1000,
      );

      expect(entry.effectiveProgressPercent, 100);
    });

    test('progressPercent salvo tem prioridade sobre scroll', () {
      contentService.saveScrollPosition(
        'nr-06',
        100,
        scrollMaxExtent: 1000,
        progressPercent: 42,
      );

      expect(contentService.getReadingProgressPercent('nr-06'), 42);
    });

    test(
      'getContinueReadingPositionLabel prioriza heading sobre item obsoleto',
      () {
        contentService.saveScrollPosition(
          'nr-06',
          500,
          scrollMaxExtent: 1000,
          lastHeadingViewed: '6.5 Objetivo',
          lastItemNumber: '6.1.1',
          replacePositionLabels: true,
        );

        expect(
          contentService.getContinueReadingPositionLabel('nr-06'),
          '6.5 Objetivo',
        );
      },
    );

    test('replacePositionLabels limpa lastItemNumber ao mudar de seção', () {
      contentService.saveScrollPosition(
        'nr-06',
        400,
        scrollMaxExtent: 1000,
        lastHeadingViewed: '6.1 Objetivo',
        lastItemNumber: '6.1.1',
        replacePositionLabels: true,
      );

      contentService.saveScrollPosition(
        'nr-06',
        600,
        scrollMaxExtent: 1000,
        lastHeadingViewed: '6.2 Campo de aplicação',
        lastItemNumber: null,
        replacePositionLabels: true,
      );

      final entry = contentService.getReadingHistoryEntry('nr-06');
      expect(entry?.lastHeadingViewed, '6.2 Campo de aplicação');
      expect(entry?.lastItemNumber, isNull);
      expect(
        contentService.getContinueReadingPositionLabel('nr-06'),
        '6.2 Campo de aplicação',
      );
    });

    test('saveScrollPosition preserva razão quando maxExtent cresce', () {
      contentService.saveScrollPosition('nr-06', 800, scrollMaxExtent: 1000);
      expect(contentService.getReadingProgressPercent('nr-06'), 80);

      contentService.saveScrollPosition('nr-06', 800, scrollMaxExtent: 4000);

      final entry = contentService.getReadingHistoryEntry('nr-06');
      expect(entry?.scrollPosition, 3200);
      expect(entry?.scrollMaxExtent, 4000);
      expect(contentService.getReadingProgressPercent('nr-06'), 80);
    });
  });
}
