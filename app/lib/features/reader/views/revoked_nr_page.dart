import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tela informativa para NRs revogadas — evita consulta acidental sem contexto.
class RevokedNrPage extends StatelessWidget {
  final ManifestEntry entry;

  const RevokedNrPage({required this.entry, super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();
    final successorId = entry.substituiPor;
    final successor = successorId != null
        ? contentService.manifest.value?.findNr(successorId)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.nrLabel),
      ),
      body: AppScaffoldBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 56,
              color: context.semanticColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'NR revogada',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Esta norma foi revogada e não deve ser usada como referência '
              'para fiscalização, laudos ou documentos de SST. Consulte o PDF '
              'oficial apenas para fins históricos ou verifique a norma vigente.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            if (entry.pdfUrl != null && entry.pdfUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _launchUrl(entry.pdfUrl!),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Ver PDF histórico no MTE'),
                ),
              ),
            if (successor != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ReaderNavigation.open(nrId: successor.id);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    'Abrir ${successor.nrLabel} (sucessora)',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Este aplicativo disponibiliza conteúdo público oficial das '
              'Normas Regulamentadoras do Ministério do Trabalho e Emprego. '
              'O conteúdo não substitui a consulta às publicações oficiais '
              'no portal gov.br.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir URL da NR revogada', e);
    }
  }
}
