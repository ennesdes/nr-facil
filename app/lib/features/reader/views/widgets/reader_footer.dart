import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Footer fixo no final de cada NR.
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

    return Container(
      color: colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nrEntry?.pdfUrl != null) ...[
            _buildPdfLink(context),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          ],
          _buildLegalDisclaimer(context),
          const SizedBox(height: AppSpacing.sm),
          if (nrEntry != null) _buildNrMetadata(context),
        ],
      ),
    );
  }

  Widget _buildPdfLink(BuildContext context) {
    final semantics = context.semanticColors;

    return InkWell(
      onTap: () => _launchPdfUrl(nrEntry?.pdfUrl),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: semantics.info, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Ver PDF original no MTE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: semantics.info,
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDisclaimer(BuildContext context) {
    return Text(
      'Este aplicativo disponibiliza conteúdo público oficial das Normas '
      'Regulamentadoras do Ministério do Trabalho e Emprego. O conteúdo não '
      'substitui a consulta às publicações oficiais no portal gov.br.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
            height: 1.4,
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
        Divider(color: textColor.withValues(alpha: 0.5)),
        const SizedBox(height: AppSpacing.xs),
        if (entry.portaria != null && entry.portaria!.trim().isNotEmpty)
          Text('Portaria: ${entry.portaria}', style: metadataStyle)
        else
          Text(
            'Portaria: conferir no PDF oficial',
            style: metadataItalicStyle,
          ),
        if (entry.publicadoEm != null)
          Text('Publicado em: ${entry.publicadoEm}', style: metadataStyle),
        if (entry.vigenteSde != null)
          Text('Vigente desde: ${entry.vigenteSde}', style: metadataStyle)
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
