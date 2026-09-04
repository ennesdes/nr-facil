import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rodapé do leitor com seção "Documento oficial" e metadados.
class ReaderFooter extends StatelessWidget {
  final String nrId;
  final ManifestEntry? nrEntry;

  const ReaderFooter({
    required this.nrId,
    required this.nrEntry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kReaderHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outline),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Documento oficial',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Esta aplicação organiza e facilita a consulta da norma, '
            'mas não substitui a publicação oficial no portal gov.br.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (nrEntry?.pdfUrl != null)
            OutlinedButton.icon(
              onPressed: () => _launchPdfUrl(nrEntry?.pdfUrl),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Ver PDF original no MTE'),
            ),
          const SizedBox(height: AppSpacing.md),
          if (nrEntry != null) _buildNrMetadata(context),
        ],
      ),
    );
  }

  Widget _buildNrMetadata(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final semantics = context.semanticColors;
    final metadataStyle = textTheme.bodySmall?.copyWith(color: textColor);
    final metadataItalicStyle = metadataStyle?.copyWith(
      fontStyle: FontStyle.italic,
    );
    final entry = nrEntry;

    if (entry == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonte: Ministério do Trabalho e Emprego',
          style: metadataStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (entry.portaria != null && entry.portaria!.trim().isNotEmpty)
          Text('Portaria: ${entry.portaria}', style: metadataStyle)
        else
          Text(
            'Portaria: conferir no PDF oficial',
            style: metadataItalicStyle,
          ),
        if (entry.publicadoEm != null)
          Text('Publicação: ${entry.publicadoEm}', style: metadataStyle),
        if (entry.vigenteSde != null)
          Text('Vigência: ${entry.vigenteSde}', style: metadataStyle)
        else if (entry.portaria == null || entry.publicadoEm == null)
          Text(
            'Datas de vigência: conferir no PDF oficial',
            style: metadataItalicStyle,
          ),
        if (entry.reviewed == true)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.verified, size: 12, color: semantics.success),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Conteúdo revisado',
                  style: textTheme.bodySmall?.copyWith(
                    color: semantics.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _launchPdfUrl(String? url) async {
    if (url == null || url.isEmpty) {
      AppLogger.warning('URL do PDF não disponível');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('Não foi possível abrir URL: $url');
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir PDF original', e);
    }
  }
}
