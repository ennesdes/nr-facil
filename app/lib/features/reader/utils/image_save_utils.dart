import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';

/// Salva uma imagem no armazenamento do dispositivo (pasta Downloads do app).
///
/// Retorna `true` se o arquivo foi copiado com sucesso.
Future<bool> saveImageToDevice({
  required String sourcePath,
  required String fileName,
}) async {
  try {
    final source = File(sourcePath);
    if (!source.existsSync()) return false;

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) return false;

    final safeName = _sanitizeFileName(fileName);
    final destination = File('${downloadsDir.path}/$safeName');
    await source.copy(destination.path);
    return true;
  } catch (e, st) {
    AppLogger.error('Falha ao salvar imagem no dispositivo', e, st);
    return false;
  }
}

/// Baixa uma imagem remota para arquivo temporário e retorna o caminho local.
Future<String?> downloadRemoteImage(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/nr_image_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  } catch (e, st) {
    AppLogger.error('Falha ao baixar imagem remota', e, st);
    return null;
  }
}

String _sanitizeFileName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'imagem-nr-facil.png';

  final base = trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  if (base.toLowerCase().endsWith('.png') ||
      base.toLowerCase().endsWith('.jpg') ||
      base.toLowerCase().endsWith('.jpeg') ||
      base.toLowerCase().endsWith('.webp')) {
    return base;
  }
  return '$base.png';
}
