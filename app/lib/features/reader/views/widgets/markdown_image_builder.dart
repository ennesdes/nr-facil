import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:get/get.dart';

/// Builder customizado para renderizar imagens no Markdown.
///
/// Suporta:
/// - URLs remotas (http/https) — renderiza diretamente
/// - Caminhos locais (ex: assets/images/diagram.png) — carrega do cache local
/// - Fallback para ícone de erro se arquivo não existir
class NrMarkdownImageBuilder extends StatelessWidget {
  final Uri uri;
  final String nrId;
  final String? title;
  final String? alt;

  const NrMarkdownImageBuilder({
    required this.uri,
    required this.nrId,
    this.title,
    this.alt,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      final uriString = uri.toString();

      // Se for URL remota (http/https), exibir normalmente
      if (uriString.startsWith('http://') || uriString.startsWith('https://')) {
        return _buildRemoteImage(context, uriString);
      }

      // Se for caminho relativo (local), buscar no cache
      return _buildLocalImage(context, uriString);
    } catch (e) {
      AppLogger.error('Erro ao construir imagem', e);
      return _buildErrorImage(context);
    }
  }

  Widget _buildRemoteImage(BuildContext context, String url) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Image.network(
        url,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage(context);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocalImage(BuildContext context, String relativePath) {
    try {
      final contentService = Get.find<ContentService>();
      final localPath = contentService.getAssetPath(nrId, relativePath);
      final file = File(localPath);

      if (!file.existsSync()) {
        AppLogger.warning('Imagem local não encontrada: $relativePath');
        return _buildPlaceholder(context, 'Imagem não encontrada:\n$relativePath');
      }

      return Container(
        constraints: const BoxConstraints(maxHeight: 400),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Image.file(
          file,
          fit: BoxFit.fitWidth,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage(context);
          },
        ),
      );
    } catch (e) {
      AppLogger.error('Erro ao carregar imagem local: $relativePath', e);
      return _buildErrorImage(context);
    }
  }

  Widget _buildErrorImage(BuildContext context) {
    return _buildPlaceholder(
      context,
      'Erro ao carregar imagem',
    );
  }

  Widget _buildPlaceholder(BuildContext context, String message) {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        minHeight: 100,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[100],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
