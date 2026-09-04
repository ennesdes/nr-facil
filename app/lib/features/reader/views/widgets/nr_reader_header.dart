import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cabeçalho do leitor com título, vigência e link secundário para PDF.
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
    final displayTitle = formatNrTitleForDisplay(title);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kReaderHorizontalPadding,
        AppSpacing.lg,
        kReaderHorizontalPadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightedText(
            text: displayTitle,
            highlight: highlightQuery,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (nrEntry?.vigenteSde != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.circle, size: 7, color: semantics.success),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Vigente desde ${nrEntry!.vigenteSde}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
          if (nrEntry?.pdfUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => _launchPdf(nrEntry!.pdfUrl!),
              icon: Icon(Icons.picture_as_pdf, size: 16, color: semantics.info),
              label: Text(
                'Ver PDF oficial',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: semantics.info,
                    ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
