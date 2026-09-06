import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';

/// Comparação visual de tabela alterada (PNG antes vs depois).
class UpdateTableComparison extends StatelessWidget {
  final String nrId;
  final String? contentRef;
  final UpdateTableChange tabela;

  const UpdateTableComparison({
    required this.nrId,
    required this.tabela,
    this.contentRef,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.semanticColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tabela.label != null && tabela.label!.trim().isNotEmpty) ...[
          Text(
            tabela.label!.trim(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (tabela.antesAsset != null) ...[
          _UpdateTableImageSection(
            title: 'Antes',
            titleColor: semantics.muted,
            backgroundColor:
                colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
            child: _BeforeTableImage(
              nrId: nrId,
              assetPath: tabela.antesAsset!,
              contentRef: contentRef,
            ),
          ),
        ],
        if (tabela.depoisAsset != null) ...[
          if (tabela.antesAsset != null) const SizedBox(height: AppSpacing.sm),
          _UpdateTableImageSection(
            title: 'Depois',
            titleColor: semantics.warning,
            backgroundColor: semantics.warningContainer.withValues(alpha: 0.35),
            child: _AfterTableImage(
              nrId: nrId,
              assetPath: tabela.depoisAsset!,
            ),
          ),
        ],
      ],
    );
  }
}

class _UpdateTableImageSection extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color backgroundColor;
  final Widget child;

  const _UpdateTableImageSection({
    required this.title,
    required this.titleColor,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: theme.textTheme.labelMedium?.copyWith(
            color: titleColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _BeforeTableImage extends StatelessWidget {
  final String nrId;
  final String assetPath;
  final String? contentRef;

  const _BeforeTableImage({
    required this.nrId,
    required this.assetPath,
    this.contentRef,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (contentRef == null || contentRef!.isEmpty) {
      return Text(
        'Imagem anterior indisponível.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final url = AppConfig.contentAssetUrl(
      nrId,
      assetPath,
      gitRef: contentRef!,
    );

    return _NetworkTableImage(url: url);
  }
}

class _AfterTableImage extends StatelessWidget {
  final String nrId;
  final String assetPath;

  const _AfterTableImage({
    required this.nrId,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ContentService>()) {
      return _NetworkTableImage(
        url: AppConfig.contentAssetUrl(nrId, assetPath),
      );
    }

    final contentService = Get.find<ContentService>();

    return Obx(() {
      contentService.nrAssetVersions[nrId];

      final localPath = contentService.getAssetPath(nrId, assetPath);
      final file = File(localPath);

      if (file.existsSync()) {
        return _LocalTableImage(file: file);
      }

      return _NetworkTableImage(
        url: AppConfig.contentAssetUrl(nrId, assetPath),
      );
    });
  }
}

class _NetworkTableImage extends StatelessWidget {
  final String url;

  const _NetworkTableImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        url,
        fit: BoxFit.fitWidth,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const ImageShimmerPlaceholder(height: 180);
        },
        errorBuilder: (context, error, stackTrace) {
          return Text(
            'Não foi possível carregar a imagem.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        },
      ),
    );
  }
}

class _LocalTableImage extends StatelessWidget {
  final File file;

  const _LocalTableImage({required this.file});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.file(
        file,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            'Não foi possível carregar a imagem.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          );
        },
      ),
    );
  }
}
