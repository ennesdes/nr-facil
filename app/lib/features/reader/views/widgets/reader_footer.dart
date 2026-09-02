import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Footer fixo no final de cada NR.
///
/// Exibe:
/// - Link para visualizar PDF original no MTE
/// - Aviso legal: o app complementa, nunca substitui, a publicação oficial
class ReaderFooter extends StatelessWidget {
  final String nrId;
  final ManifestEntry? nrEntry;
  final bool isDarkMode;

  const ReaderFooter({
    required this.nrId,
    required this.nrEntry,
    required this.isDarkMode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkMode ? Color(0xFF2E2E2E) : Colors.grey[100],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Link para PDF original
          if (nrEntry?.pdfUrl != null) ...[
            _buildPdfLink(context),
            const SizedBox(height: 12),
          ],

          // Aviso legal
          _buildLegalDisclaimer(context),

          const SizedBox(height: 8),

          // Dados da NR
          if (nrEntry != null) ...[
            _buildNrMetadata(context),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfLink(BuildContext context) {
    return InkWell(
      onTap: () => _launchPdfUrl(nrEntry?.pdfUrl),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ver PDF original no MTE',
              style: TextStyle(
                color: Colors.blue[isDarkMode ? 300 : 600],
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDisclaimer(BuildContext context) {
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Text(
      'Este aplicativo disponibiliza conteúdo público oficial das Normas '
      'Regulamentadoras do Ministério do Trabalho e Emprego. O conteúdo não '
      'substitui a consulta às publicações oficiais no portal gov.br.',
      style: TextStyle(
        fontSize: 11,
        color: textColor,
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
    );
  }

  Widget _buildNrMetadata(BuildContext context) {
    final textColor = isDarkMode ? Colors.white54 : Colors.black45;
    final entry = nrEntry;

    if (entry == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: textColor),
        const SizedBox(height: 4),
        if (entry.portaria != null && entry.portaria!.trim().isNotEmpty)
          Text(
            'Portaria: ${entry.portaria}',
            style: TextStyle(fontSize: 10, color: textColor),
          )
        else
          Text(
            'Portaria: conferir no PDF oficial',
            style: TextStyle(fontSize: 10, color: textColor, fontStyle: FontStyle.italic),
          ),
        if (entry.publicadoEm != null)
          Text(
            'Publicado em: ${entry.publicadoEm}',
            style: TextStyle(fontSize: 10, color: textColor),
          ),
        if (entry.vigenteSde != null)
          Text(
            'Vigente desde: ${entry.vigenteSde}',
            style: TextStyle(fontSize: 10, color: textColor),
          )
        else if (entry.portaria == null || entry.publicadoEm == null)
          Text(
            'Datas de vigência: conferir no PDF oficial',
            style: TextStyle(fontSize: 10, color: textColor, fontStyle: FontStyle.italic),
          ),
        if (entry.reviewed == true)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.verified, size: 12, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Conteúdo revisado',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
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
