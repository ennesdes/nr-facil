import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/home/views/widgets/favoritos_tab.dart';
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

  group('FavoritosTab', () {
    late Directory storageDir;
    late Directory cacheDir;
    late ContentService contentService;

    setUpAll(() async {
      storageDir = await Directory.systemTemp.createTemp(
        'nr_facil_fav_tab_storage_',
      );
      PathProviderPlatform.instance = _FakePathProviderPlatform(
        storageDir.path,
      );
      await GetStorage.init();
    });

    tearDownAll(() async {
      if (storageDir.existsSync()) {
        await storageDir.delete(recursive: true);
      }
    });

    setUp(() async {
      Get.testMode = true;
      GetStorage().erase();

      cacheDir = await Directory.systemTemp.createTemp(
        'nr_facil_fav_tab_cache_',
      );
      contentService = ContentService(cacheDirOverride: cacheDir);
      Get.put<ContentService>(contentService);

      contentService.favoriteIds.assignAll(['nr-06']);
      contentService.favoritesVersion.value++;
      GetStorage().write(StorageKeys.favoriteNrs, ['nr-06']);
    });

    tearDown(() async {
      contentService.onClose();
      Get.reset();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    });

    testWidgets('não remove favoritos enquanto manifest ainda não carregou', (
      tester,
    ) async {
      expect(contentService.manifest.value, isNull);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: FavoritosTab()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(contentService.favoriteIds, ['nr-06']);
      expect(GetStorage().read<List>(StorageKeys.favoriteNrs), ['nr-06']);
    });
  });
}
