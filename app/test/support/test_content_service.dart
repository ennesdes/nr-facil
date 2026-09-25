import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nrfacil/core/services/content_service.dart';

import 'offline_http_client.dart';

/// [ContentService] para testes — nunca usa rede real (MockClient por padrão).
ContentService createTestContentService(
  Directory cacheDir, {
  http.Client? httpClient,
}) {
  return ContentService(
    httpClient: httpClient ?? createOfflineHttpClient(),
    cacheDirOverride: cacheDir,
  );
}
