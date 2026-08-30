import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cabeçalho do leitor com título, metadados e link para PDF oficial.
class NrReaderHeader extends StatelessWidget {
  final String title;
  final ManifestEntry? nrEntry;
  final bool isDarkMode;
  final String? highlightQuery;

  const NrReaderHeader({
    required this.title,
    required this.nrEntry,
    required this.isDarkMode,
    this.highlightQuery,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HighlightedText(
            text: title,
            highlight: highlightQuery,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
          ),
          if (nrEntry?.vigenteSde != null) ...[
            const SizedBox(height: 8),
            Chip(
              label: Text(
                'Vigente desde ${nrEntry!.vigenteSde}',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
          if (nrEntry?.pdfUrl != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _launchPdf(nrEntry!.pdfUrl!),
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Ver PDF oficial no MTE'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[isDarkMode ? 300 : 700],
              ),
            ),
          ],
          if (nrEntry?.portaria != null) ...[
            const SizedBox(height: 8),
            HighlightedText(
              text: nrEntry!.portaria!,
              highlight: highlightQuery,
              style: TextStyle(fontSize: 12, color: subtitleColor),
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
