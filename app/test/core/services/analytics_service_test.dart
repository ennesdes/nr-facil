import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/analytics_service.dart';

import '../../support/fake_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  group('AnalyticsService', () {
    test('sem Firebase inicializado todos os métodos são no-op', () async {
      final service = AnalyticsService();

      await service.logScreen(AnalyticsService.screenReader);
      await service.logOpenNr('nr-06', source: AnalyticsService.sourceNormas);
      await service.logSearch('epi', 3);
      await service.logFavorite('nr-06', added: true);
      await service.logOpenOfficialPdf('nr-06');
      await service.logOpenUpdates();
    });

    test('maybe retorna null sem registro e a instância quando registrada', () {
      expect(AnalyticsService.maybe, isNull);
      final service = Get.put<AnalyticsService>(FakeAnalyticsService());
      expect(AnalyticsService.maybe, same(service));
    });

    test('logSearch trunca termo e ignora termo vazio', () async {
      final fake = FakeAnalyticsService();

      await fake.logSearch('   ', 0);
      await fake.logSearch('  ${'a' * 150}  ', 7);

      expect(fake.events, hasLength(1));
      final (name, params) = fake.events.single;
      expect(name, AnalyticsService.eventSearch);
      expect(
        params[AnalyticsService.paramSearchTerm],
        'a' * AnalyticsService.maxParamLength,
      );
      expect(params[AnalyticsService.paramResultCount], 7);
    });

    test('logFavorite usa evento de add/remove', () async {
      final fake = FakeAnalyticsService();

      await fake.logFavorite('nr-06', added: true);
      await fake.logFavorite('nr-06', added: false);

      expect(fake.events.map((e) => e.$1), [
        AnalyticsService.eventFavoriteAdd,
        AnalyticsService.eventFavoriteRemove,
      ]);
      expect(fake.events.first.$2, {AnalyticsService.paramNrId: 'nr-06'});
    });

    test('logOpenNr envia nr_id e source', () async {
      final fake = FakeAnalyticsService();

      await fake.logOpenNr('nr-35', source: AnalyticsService.sourceBusca);

      final (name, params) = fake.events.single;
      expect(name, AnalyticsService.eventOpenNr);
      expect(params, {
        AnalyticsService.paramNrId: 'nr-35',
        AnalyticsService.paramSource: AnalyticsService.sourceBusca,
      });
    });
  });
}
