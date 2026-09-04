import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nrfacil/core/widgets/app_shimmer.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
import 'package:nrfacil/features/reader/utils/image_save_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Visualizador em tela cheia com zoom (pinça e duplo toque), arrastar e ações.
class NrImageViewer extends StatefulWidget {
  final ImageProvider imageProvider;
  final String? localFilePath;
  final String? remoteUrl;
  final String fileName;
  final String? caption;

  const NrImageViewer({
    required this.imageProvider,
    required this.fileName,
    this.localFilePath,
    this.remoteUrl,
    this.caption,
    super.key,
  });

  static Future<void> open({
    required BuildContext context,
    required ImageProvider imageProvider,
    required String fileName,
    String? localFilePath,
    String? remoteUrl,
    String? caption,
  }) {
    AppLogger.debug(
      'NrImageViewer.open fileName=$fileName '
      'local=${localFilePath != null} remote=${remoteUrl != null} '
      'caption=${caption ?? '(sem legenda)'}',
    );
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => NrImageViewer(
          imageProvider: imageProvider,
          fileName: fileName,
          localFilePath: localFilePath,
          remoteUrl: remoteUrl,
          caption: caption,
        ),
      ),
    );
  }

  @override
  State<NrImageViewer> createState() => _NrImageViewerState();
}

class _NrImageViewerState extends State<NrImageViewer> {
  static const _doubleTapScale = 2.5;
  static const _minScale = 0.8;
  static const _maxScale = 5.0;

  final _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isSaving = false;
  bool _loggedLayout = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_logTransformation);
    AppLogger.debug('NrImageViewer initState fileName=${widget.fileName}');
  }

  @override
  void dispose() {
    _transformationController.removeListener(_logTransformation);
    AppLogger.debug('NrImageViewer dispose fileName=${widget.fileName}');
    _transformationController.dispose();
    super.dispose();
  }

  void _logTransformation() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    AppLogger.debug(
      'NrImageViewer transform scale=${scale.toStringAsFixed(3)} '
      'tx=${matrix.storage[12].toStringAsFixed(1)} '
      'ty=${matrix.storage[13].toStringAsFixed(1)}',
    );
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
    AppLogger.debug(
      'NrImageViewer doubleTapDown local=(${details.localPosition.dx.toStringAsFixed(1)}, '
      '${details.localPosition.dy.toStringAsFixed(1)}) '
      'global=(${details.globalPosition.dx.toStringAsFixed(1)}, '
      '${details.globalPosition.dy.toStringAsFixed(1)})',
    );
  }

  void _onDoubleTap() {
    final details = _doubleTapDetails;
    if (details == null) {
      AppLogger.warning('NrImageViewer doubleTap sem doubleTapDown');
      return;
    }

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    AppLogger.debug(
      'NrImageViewer doubleTap currentScale=${currentScale.toStringAsFixed(3)}',
    );

    if (currentScale > 1.05) {
      AppLogger.debug('NrImageViewer doubleTap → reset (zoom out)');
      _transformationController.value = Matrix4.identity();
      return;
    }

    // Ponto de toque no espaço da cena (considera transformação atual).
    final focalPoint = _transformationController.toScene(details.localPosition);
    final scale = _doubleTapScale;
    final tx = focalPoint.dx * (1 - scale);
    final ty = focalPoint.dy * (1 - scale);
    AppLogger.debug(
      'NrImageViewer doubleTap → zoom in focal=(${focalPoint.dx.toStringAsFixed(1)}, '
      '${focalPoint.dy.toStringAsFixed(1)}) scale=$scale '
      'tx=${tx.toStringAsFixed(1)} ty=${ty.toStringAsFixed(1)}',
    );
    // Matrix4 em Flutter é column-major: translação fica em storage[12]/[13].
    _transformationController.value = Matrix4(
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, 1, 0,
      tx, ty, 0, 1,
    );
  }

  Future<String?> _resolveShareablePath() async {
    final localPath = widget.localFilePath;
    if (localPath != null && File(localPath).existsSync()) {
      AppLogger.debug('NrImageViewer resolvePath local ok exists=true');
      return localPath;
    }

    AppLogger.debug(
      'NrImageViewer resolvePath local missing=${localPath ?? '(null)'} '
      'exists=${localPath != null && File(localPath).existsSync()}',
    );

    final remoteUrl = widget.remoteUrl;
    if (remoteUrl != null) {
      AppLogger.debug('NrImageViewer resolvePath baixando remoto');
      return downloadRemoteImage(remoteUrl);
    }

    AppLogger.warning('NrImageViewer resolvePath sem local nem remoto');
    return null;
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;
    AppLogger.debug('NrImageViewer save iniciado');
    setState(() => _isSaving = true);

    try {
      final path = await _resolveShareablePath();
      if (path == null) {
        if (mounted) {
          AppSnackbar.showError(
            title: 'Salvar imagem',
            message: 'Não foi possível salvar a imagem.',
          );
        }
        return;
      }

      final saved = await saveImageToDevice(
        sourcePath: path,
        fileName: widget.fileName,
      );

      if (!mounted) return;

      if (saved) {
        AppLogger.debug('NrImageViewer save ok');
        AppSnackbar.showSuccess(
          title: 'Imagem salva',
          message: 'A imagem foi salva no dispositivo.',
        );
      } else {
        AppLogger.debug('NrImageViewer save fallback share sheet');
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path, name: widget.fileName)]),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareImage() async {
    if (_isSaving) return;
    AppLogger.debug('NrImageViewer share iniciado');
    setState(() => _isSaving = true);

    try {
      final path = await _resolveShareablePath();
      if (path == null) {
        if (mounted) {
          AppSnackbar.showError(
            title: 'Compartilhar imagem',
            message: 'Não foi possível compartilhar a imagem.',
          );
        }
        return;
      }

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, name: widget.fileName)]),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        title: caption == null || caption.isEmpty
            ? null
            : Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: AppShimmerIcon(size: 20),
            )
          else ...[
            IconButton(
              tooltip: 'Salvar imagem',
              onPressed: _saveImage,
              icon: const Icon(Icons.download_outlined),
            ),
            IconButton(
              tooltip: 'Compartilhar',
              onPressed: _shareImage,
              icon: const Icon(Icons.share_outlined),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!_loggedLayout) {
                  _loggedLayout = true;
                  AppLogger.debug(
                    'NrImageViewer layout '
                    '${constraints.maxWidth.toStringAsFixed(0)}x'
                    '${constraints.maxHeight.toStringAsFixed(0)}',
                  );
                }
                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.none,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTapDown: _onDoubleTapDown,
                    onDoubleTap: _onDoubleTap,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: Image(
                        image: widget.imageProvider,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            child: IgnorePointer(
              child: Text(
                'Pinça ou duplo toque para ampliar · Arraste para mover',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
