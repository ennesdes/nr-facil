import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart';
import 'package:nrfacil/core/utils/user_messages.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_image_viewer.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';
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
    super.key,
  });

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
    return _tappable(
      context,
      Container(
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
            return const ImageShimmerPlaceholder(height: 200);
          },
        ),
      ),
      imageProvider: NetworkImage(url),
      remoteUrl: url,
    );
  }

  Widget _buildLocalImage(BuildContext context, String relativePath) {
    final contentService = Get.find<ContentService>();

    return Obx(() {
      // Rebuild quando assets terminarem de baixar em background.
      contentService.nrAssetVersions[nrId];

      try {
        final localPath = _resolveLocalPath(contentService, relativePath);
        final file = File(localPath);

        if (!file.existsSync()) {
          AppLogger.warning('Imagem local não encontrada: $relativePath');
          return _buildPlaceholder(context, UserMessages.imageUnavailable);
        }

        final preview = Image.file(file, fit: BoxFit.fitWidth);

        return _tappable(
          context,
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: preview,
          ),
          imageProvider: FileImage(file),
          localFilePath: localPath,
        );
      } catch (e) {
        AppLogger.error('Erro ao carregar imagem local: $relativePath', e);
        return _buildErrorImage(context);
      }
    });
  }

  String _resolveLocalPath(ContentService contentService, String relativePath) {
    return contentService.getAssetPath(nrId, relativePath);
  }

  Widget _tappable(
    BuildContext context,
    Widget preview, {
    required ImageProvider imageProvider,
    String? localFilePath,
    String? remoteUrl,
  }) {
    return GestureDetector(
      onTap: () {
        AppLogger.debug(
          'MarkdownImage tap nrId=$nrId '
          'local=${localFilePath != null} remote=${remoteUrl != null} '
          'exists=${localFilePath != null && File(localFilePath).existsSync()}',
        );
        NrImageViewer.open(
          context: context,
          imageProvider: imageProvider,
          localFilePath: localFilePath,
          remoteUrl: remoteUrl,
          fileName: _suggestFileName(),
          caption: alt ?? title,
        );
      },
      child: preview,
    );
  }

  String _suggestFileName() {
    final label = formatNrLabel(nrId);
    final description = (alt ?? title)?.trim();
    if (description != null && description.isNotEmpty) {
      final sanitized = description.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      return '$label-$sanitized.png';
    }
    return '$label-imagem.png';
  }

  Widget _buildErrorImage(BuildContext context) {
    return _buildPlaceholder(context, UserMessages.imageLoadFailed);
  }

  Widget _buildPlaceholder(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        minHeight: 100,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
        color: colorScheme.surfaceContainerHighest,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
