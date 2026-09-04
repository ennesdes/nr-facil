import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/services/content_service.dart';

void main() {
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
      final cacheDir = await Directory.systemTemp.createTemp('nr_facil_assets_');
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
