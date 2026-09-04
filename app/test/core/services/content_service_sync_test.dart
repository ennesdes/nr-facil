import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
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

  group('ContentService sync sob demanda', () {
    late Directory storageDir;
    late Directory cacheDir;
    late ContentService contentService;

    final manifestJson = {
      'generated_at': '2026-01-01T00:00:00.000Z',
      'version': 1,
      'nrs': [
        {
          'id': 'nr-06',
          'title': 'EPI',
          'version': '1',
          'hash': 'hash-06',
          'pdf_hash': 'pdf-06',
          'updated_at': '2026-01-01T00:00:00.000Z',
          'url':
              '${AppConfig.contentBaseUrl}/nr-06/nr-06.md',
          'revogada': false,
        },
        {
          'id': 'nr-10',
          'title': 'Máquinas',
          'version': '1',
          'hash': 'hash-10',
          'pdf_hash': 'pdf-10',
          'updated_at': '2026-01-01T00:00:00.000Z',
          'url':
              '${AppConfig.contentBaseUrl}/nr-10/nr-10.md',
          'revogada': false,
        },
      ],
    };

  http.Client buildMockClient({Set<String> allowedSuffixes = const {}}) {
      return MockClient((request) async {
        final path = request.url.path;

        if (path.endsWith('/manifest.json')) {
          return http.Response(jsonEncode(manifestJson), 200);
        }
        if (path.endsWith('/app_meta.json')) {
          return http.Response(
            jsonEncode({
              'generated_at': '2026-01-01T00:00:00.000Z',
              'min_app_version': '0.0.1',
              'updates': [],
            }),
            200,
          );
        }

        if (allowedSuffixes.any(path.endsWith)) {
          return http.Response('payload', 200);
        }

        return http.Response('not found', 404);
      });
    }

    setUpAll(() async {
      storageDir = await Directory.systemTemp.createTemp('nr_facil_storage_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(storageDir.path);
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

      cacheDir = await Directory.systemTemp.createTemp('nr_facil_cache_');
      contentService = ContentService(
        httpClient: buildMockClient(
          allowedSuffixes: {
            'nr-06/search_index.json',
            'nr-10/search_index.json',
          },
        ),
        cacheDirOverride: cacheDir,
      );
      await contentService.onInit();
    });

    tearDown(() async {
      contentService.onClose();
      Get.reset();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    });

    test('syncMetadata não baixa conteúdo completo das NRs', () async {
      final ok = await contentService.syncMetadata();

      expect(ok, isTrue);
      expect(contentService.manifest.value?.nrs.length, 2);
      expect(
        File('${cacheDir.path}/content/nr-06/nr-06.md').existsSync(),
        isFalse,
      );
    });

    test('syncSearchIndices baixa apenas search_index.json', () async {
      await contentService.syncMetadata();
      await contentService.syncSearchIndices();

      expect(
        File('${cacheDir.path}/content/nr-06/search_index.json').existsSync(),
        isTrue,
      );
      expect(
        File('${cacheDir.path}/content/nr-06/nr-06.md').existsSync(),
        isFalse,
      );
      expect(
        GetStorage().read(StorageKeys.nrSearchIndexSyncedHash('nr-06')),
        'hash-06',
      );
    });

    test('prefetchFavorites baixa apenas favoritas desatualizadas', () async {
      contentService.onClose();

      contentService = ContentService(
        httpClient: buildMockClient(
          allowedSuffixes: {
            'nr-06/nr-06.md',
            'nr-06/index.json',
            'nr-06/structure.json',
            'nr-06/search_index.json',
          },
        ),
        cacheDirOverride: cacheDir,
      );
      await contentService.onInit();
      await contentService.syncMetadata();

      contentService.favoriteIds.addAll(['nr-06', 'nr-10']);
      await contentService.prefetchFavorites();

      expect(
        File('${cacheDir.path}/content/nr-06/nr-06.md').existsSync(),
        isTrue,
      );
      expect(
        File('${cacheDir.path}/content/nr-10/nr-10.md').existsSync(),
        isFalse,
      );
    });

    test('downloadNrForReading grava core antes do pacote completo', () async {
      contentService.onClose();

      contentService = ContentService(
        httpClient: buildMockClient(
          allowedSuffixes: {
            'nr-06/nr-06.md',
            'nr-06/index.json',
            'nr-06/structure.json',
            'nr-06/search_index.json',
          },
        ),
        cacheDirOverride: cacheDir,
      );
      await contentService.onInit();
      await contentService.syncMetadata();

      final ok = await contentService.downloadNrForReading('nr-06');

      expect(ok, isTrue);
      expect(contentService.isNrContentCached('nr-06'), isTrue);
      expect(
        GetStorage().read(StorageKeys.nrCoreSyncedHash('nr-06')),
        'hash-06',
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(contentService.isNrFullyCached('nr-06'), isTrue);
    });

    test('isNrContentCached e isNrFullyCached refletem estado local', () async {
      await contentService.syncMetadata();

      expect(contentService.isNrContentCached('nr-06'), isFalse);
      expect(contentService.isNrFullyCached('nr-06'), isFalse);

      final nrDir = Directory('${cacheDir.path}/content/nr-06');
      nrDir.createSync(recursive: true);
      File('${nrDir.path}/nr-06.md').writeAsStringSync('# NR-06');
      GetStorage().write(StorageKeys.nrCoreSyncedHash('nr-06'), 'hash-06');

      expect(contentService.isNrContentCached('nr-06'), isTrue);
      expect(contentService.isNrFullyCached('nr-06'), isFalse);

      GetStorage().write(StorageKeys.nrLastSyncedHash('nr-06'), 'hash-06');
      expect(contentService.isNrFullyCached('nr-06'), isTrue);
    });
  });
}
