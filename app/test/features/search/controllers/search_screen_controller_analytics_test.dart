import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/analytics_service.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/services/search_service.dart';
import 'package:nrfacil/features/search/controllers/search_screen_controller.dart';

import '../../../support/fake_analytics_service.dart';

class _FakeContentService implements ContentService {
  @override
  final isSearchIndexSyncing = false.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSearchService implements SearchService {
  @override
  final isLoading = false.obs;

  @override
  Future<List<SearchResult>> search(String query, {String? nrFilter}) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('busca registra evento search com termo e quantidade', () async {
    final analytics = Get.put<AnalyticsService>(
      FakeAnalyticsService(),
    ) as FakeAnalyticsService;
    final controller = SearchScreenController(
      searchService: _FakeSearchService(),
      contentService: _FakeContentService(),
    )..onInit();

    controller.queryController.text = 'extintor';
    await controller.performSearchNow();

    final (name, params) = analytics.events.single;
    expect(name, AnalyticsService.eventSearch);
    expect(params, {
      AnalyticsService.paramSearchTerm: 'extintor',
      AnalyticsService.paramResultCount: 0,
    });
    controller.onClose();
  });
}
