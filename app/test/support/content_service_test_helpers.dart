import 'dart:convert';
import 'dart:io';

/// Manifest em cache sem NRs — simula boot antes do sync remoto (sem asset embutido).
Future<void> seedEmptyManifestCache(Directory cacheDir) async {
  final manifestFile = File('${cacheDir.path}/manifest.json');
  await manifestFile.parent.create(recursive: true);
  await manifestFile.writeAsString(
    jsonEncode({
      'generated_at': '2026-01-01T00:00:00.000Z',
      'version': 1,
      'nrs': <Map<String, dynamic>>[],
    }),
  );
}
