import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cabeçalho do leitor com título, metadados e link para PDF oficial.
class NrReaderHeader extends StatelessWidget {
  final String title;
  final ManifestEntry? nrEntry;
  final String? highlightQuery;

  const NrReaderHeader({
    required this.title,
    required this.nrEntry,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantics = context.semanticColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightedText(
            text: title,
            highlight: highlightQuery,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
          ),
          if (nrEntry?.vigenteSde != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Chip(
              label: Text(
                'Vigente desde ${nrEntry!.vigenteSde}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
          if (nrEntry?.pdfUrl != null) ...[
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            OutlinedButton.icon(
              onPressed: () => _launchPdf(nrEntry!.pdfUrl!),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Ver PDF oficial no MTE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: semantics.info,
              ),
            ),
          ],
          if (nrEntry?.portaria != null) ...[
            const SizedBox(height: AppSpacing.sm),
            HighlightedText(
              text: nrEntry!.portaria!,
              highlight: highlightQuery,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _launchPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir PDF', e);
    }
  }
}
