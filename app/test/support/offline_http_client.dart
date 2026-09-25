import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Cliente HTTP local para testes — intercepta manifest/app_meta e devolve 404 no resto.
///
/// Use via [createTestContentService] em qualquer teste que instancie [ContentService]
/// e possa chamar `syncMetadata`, `prefetchFavorites` ou downloads.
http.Client createOfflineHttpClient() {
  return MockClient((request) async {
    final path = request.url.path;

    if (path.endsWith('/manifest.json')) {
      return http.Response(
        jsonEncode({
          'generated_at': '2026-01-01T00:00:00.000Z',
          'version': 1,
          'nrs': <Map<String, dynamic>>[],
        }),
        200,
      );
    }

    if (path.endsWith('/app_meta.json')) {
      return http.Response(
        jsonEncode({
          'generated_at': '2026-01-01T00:00:00.000Z',
          'min_app_version': '0.0.1',
          'updates': <Map<String, dynamic>>[],
        }),
        200,
      );
    }

    return http.Response('offline test client', 404);
  });
}
