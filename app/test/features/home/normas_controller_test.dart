import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/home/controllers/normas_controller.dart';

Manifest _manifest() {
  return Manifest(
    generatedAt: DateTime(2024, 1, 1),
    version: 1,
    nrs: [
      ManifestEntry(
        id: 'nr-01',
        title: 'DISPOSIÇÕES GERAIS',
        version: '1',
        hash: 'a',
        pdfHash: 'b',
        updatedAt: DateTime(2024, 1, 1),
        url: 'https://example.com/nr-01.md',
      ),
      ManifestEntry(
        id: 'nr-02',
        title: 'INSPEÇÃO PRÉVIA',
        version: '1',
        hash: 'c',
        pdfHash: 'd',
        updatedAt: DateTime(2024, 1, 1),
        url: 'https://example.com/nr-02.md',
        revogada: true,
      ),
      ManifestEntry(
        id: 'nr-06',
        title: 'EPI',
        version: '1',
        hash: 'e',
        pdfHash: 'f',
        updatedAt: DateTime(2024, 1, 1),
        url: 'https://example.com/nr-06.md',
      ),
    ],
  );
}

void main() {
  late ContentService contentService;
  late NormasController controller;

  setUp(() {
    Get.testMode = true;
    contentService = ContentService();
    contentService.manifest.value = _manifest();
    controller = NormasController(contentService: contentService);
    Get.put(controller);
  });

  tearDown(() {
    Get.reset();
  });

  test('filtra por busca local em título e número', () {
    controller.setQuery('epi');
    expect(controller.filteredEntries.map((e) => e.id), ['nr-06']);

    controller.setQuery('nr-01');
    expect(controller.filteredEntries.map((e) => e.id), ['nr-01']);
  });

  test('filtra revogadas', () {
    controller.setFilter(NormasFilter.revoked);
    expect(controller.filteredEntries.map((e) => e.id), ['nr-02']);
  });

  test('filtra favoritas', () {
    contentService.favoriteIds.assignAll(['nr-06']);
    controller.setFilter(NormasFilter.favorites);
    expect(controller.filteredEntries.map((e) => e.id), ['nr-06']);
  });
}
