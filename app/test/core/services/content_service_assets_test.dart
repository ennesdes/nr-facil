import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
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

  setUpAll(() async {
    final storageDir = await Directory.systemTemp.createTemp(
      'nr_facil_assets_storage_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(storageDir.path);
    await GetStorage.init();
  });

  group('ContentService.collectAssetPaths', () {
    test('extrai assets com prefixo ../ do markdown', () {
      const md = '''
Texto normativo.

![Quadro I](../assets/pages/page-011-table-00.png)
''';

      final paths = ContentService.collectAssetPaths(markdown: md);

      expect(paths, {'assets/pages/page-011-table-00.png'});
    });

    test('extrai assets referenciados no structure.json', () {
      const structureJson = '''
{
  "sections": [{
    "blocks": [{
      "type": "image",
      "alt": "Tabela",
      "src": "../assets/pages/page-004-table-00.png"
    }]
  }]
}
''';

      final paths = ContentService.collectAssetPaths(
        markdown: '',
        structureJson: structureJson,
      );

      expect(paths, {'assets/pages/page-004-table-00.png'});
    });
  });

  group('ContentService.getAssetPath', () {
    test('resolve caminho sem duplicar prefixo assets/', () async {
      final cacheDir = await Directory.systemTemp.createTemp(
        'nr_facil_assets_',
      );
      final service = ContentService(cacheDirOverride: cacheDir);
      await service.onInit();

      final path = service.getAssetPath(
        'nr-36',
        '../assets/pages/page-027-image-00.png',
      );

      expect(
        path,
        '${cacheDir.path}/content/nr-36/assets/pages/page-027-image-00.png',
      );

      service.onClose();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    });
  });
}
