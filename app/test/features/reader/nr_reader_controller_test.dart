import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Mock simples de ContentService — mesmo padrão de
/// test/features/home/controllers/home_controller_test.dart.
class FakeContentService implements ContentService {
  @override
  final favoriteIds = <String>[].obs;

  @override
  final lastError = Rxn<String>();

  @override
  final manifest = Rxn();

  @override
  final appMeta = Rxn();

  @override
  final isSyncing = false.obs;

  @override
  final lastSyncedAt = Rxn<DateTime>();

  @override
  final unreadUpdatesCount = 0.obs;

  /// Controla o retorno de hasUpdate() nos testes
  bool hasUpdateResult = false;

  /// Controla o retorno de updateEntryFor() nos testes
  UpdateEntry? updateEntryResult;

  /// Registra as chamadas a markNrAsSeen() para asserção nos testes
  final List<String> markNrAsSeenCalls = [];

  @override
  bool isFavorite(String nrId) => favoriteIds.contains(nrId);

  @override
  bool hasUpdate(String nrId) => hasUpdateResult;

  @override
  UpdateEntry? updateEntryFor(String nrId) => updateEntryResult;

  @override
  void markNrAsSeen(String nrId) {
    markNrAsSeenCalls.add(nrId);
  }

  @override
  double getScrollPosition(String nrId) => 0.0;

  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('NRReaderController — banner de atualização (CA7)', () {
    late FakeContentService fakeContentService;
    late NRReaderController controller;

    setUp(() {
      Get.testMode = true;
      fakeContentService = FakeContentService();
      controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fakeContentService,
      );
    });

    tearDown(() {
      Get.reset();
    });

    test(
        'dismissUpdateBanner() esconde o banner e marca a NR como vista',
        () {
      // Simula estado após onInit ter detectado atualização pendente
      controller.showUpdateBanner.value = true;

      controller.dismissUpdateBanner();

      expect(controller.showUpdateBanner.value, false);
      expect(fakeContentService.markNrAsSeenCalls, ['nr-06']);
    });

    test(
        'dismissUpdateBanner() chamado ao dispensar (X) e ao abrir o CTA '
        'ambos marcam como vista (mesma chamada subjacente)', () {
      // Dispensar (X)
      controller.showUpdateBanner.value = true;
      controller.dismissUpdateBanner();
      expect(fakeContentService.markNrAsSeenCalls.length, 1);

      // Abrir CTA "Ver o que mudou" também chama dismissUpdateBanner()
      // (ver update_banner.dart — botão "Ver" também invoca o mesmo método)
      controller.showUpdateBanner.value = true;
      controller.dismissUpdateBanner();
      expect(fakeContentService.markNrAsSeenCalls.length, 2);
    });

    test('getUpdateEntry() retorna a UpdateEntry da NR atual via ContentService',
        () {
      final entry = UpdateEntry(
        nrId: 'nr-06',
        title: 'NR-06',
        hash: 'abc123',
        summary: '1 item alterado',
        items: [UpdateItem(item: '6.5', tipo: 'alterado', resumo: 'texto')],
      );
      fakeContentService.updateEntryResult = entry;

      expect(controller.getUpdateEntry(), same(entry));
    });

    test('getUpdateEntry() retorna null quando não há entrada correspondente',
        () {
      fakeContentService.updateEntryResult = null;

      expect(controller.getUpdateEntry(), isNull);
    });

    test('showUpdateBanner começa false antes de qualquer carregamento', () {
      // Estado inicial do Rx, antes de onInit() rodar — nunca deve mostrar
      // o banner "por padrão" sem checagem explícita de hasUpdate().
      expect(controller.showUpdateBanner.value, false);
    });
  });
}
