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
      PathProviderPlatform.instance =
          _FakePathProviderPlatform(storageDir.path);
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
      expect(
        GetStorage().read<String>(StorageKeys.lastOpenedNr),
        'nr-06',
      );
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

      contentService.saveScrollPosition(
        'nr-06',
        1000,
        scrollMaxExtent: 1000,
      );

      expect(contentService.readingHistoryVersion.value, before + 1);
      expect(contentService.getReadingProgressPercent('nr-06'), 100);
    });

    test('ReadingHistoryEntry progressPercent no final do scroll', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2026),
        scrollPosition: 999.5,
        scrollMaxExtent: 1000,
      );

      expect(entry.progressPercent, 100);
    });

    test('saveScrollPosition preserva razão quando maxExtent cresce', () {
      contentService.saveScrollPosition(
        'nr-06',
        800,
        scrollMaxExtent: 1000,
      );
      expect(contentService.getReadingProgressPercent('nr-06'), 80);

      contentService.saveScrollPosition(
        'nr-06',
        800,
        scrollMaxExtent: 4000,
      );

      final entry = contentService.getReadingHistoryEntry('nr-06');
      expect(entry?.scrollPosition, 3200);
      expect(entry?.scrollMaxExtent, 4000);
      expect(contentService.getReadingProgressPercent('nr-06'), 80);
    });
  });
}
