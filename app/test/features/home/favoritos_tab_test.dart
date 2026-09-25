import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';
import 'package:nrfacil/features/home/views/widgets/favoritos_tab.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../support/content_service_test_helpers.dart';
import '../../support/offline_http_client.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

Future<void> _waitForServiceBoot(ContentService service) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (service.manifest.value == null && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  if (service.manifest.value == null) {
    fail('ContentService não concluiu onInit() a tempo');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritosTab', () {
    late Directory workDir;
    late ContentService contentService;

    setUp(() async {
      Get.testMode = true;
      workDir = await Directory.systemTemp.createTemp('nr_facil_fav_tab_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(workDir.path);

      await GetStorage.init();
      GetStorage().erase();
      GetStorage().write(StorageKeys.favoriteNrs, ['nr-06']);

      await seedEmptyManifestCache(workDir);

      contentService = ContentService(
        httpClient: createOfflineHttpClient(),
        cacheDirOverride: workDir,
      );
      Get.put<ContentService>(contentService, permanent: true);
      await _waitForServiceBoot(contentService);
    });

    tearDown(() async {
      contentService.cancelBulkSync();
      contentService.onClose();
      Get.reset();
      for (var attempt = 0; attempt < 3; attempt++) {
        if (!workDir.existsSync()) break;
        try {
          await workDir.delete(recursive: true);
          break;
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
    });

    testWidgets('não remove favoritos enquanto manifest ainda não carregou', (
      tester,
    ) async {
      expect(contentService.isManifestLoading, isTrue);
      expect(contentService.favoriteIds, ['nr-06']);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: FavoritosTab()),
        ),
      );
      await tester.pump();

      expect(find.byType(NormasTabShimmer), findsOneWidget);
      expect(contentService.favoriteIds, ['nr-06']);
      expect(GetStorage().read<List>(StorageKeys.favoriteNrs), ['nr-06']);
    });
  });
}
