import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Diálogo bloqueante de atualização obrigatória.
///
/// Exibido quando a versão instalada está abaixo de `min_app_version` em `app_meta.json`.
/// Não pode ser dispensado tocando fora nem pelo botão de voltar.
/// Redireciona para a Play Store ao tocar o botão de atualização.
class ForcedUpdateDialog extends StatelessWidget {
  /// URL do app na Play Store
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.douglasennes.nrfacil';

  const ForcedUpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: Icon(
          Icons.system_update_alt,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Atualização obrigatória'),
        content: const Text(
          'Uma nova versão do NR Fácil é necessária para continuar usando o app. '
          'Por favor, atualize na Play Store.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _openPlayStore(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text('Atualizar na Play Store'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Abrir URL da Play Store usando url_launcher.
  Future<void> _openPlayStore() async {
    try {
      final uri = Uri.parse(_playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('Não foi possível abrir a Play Store: $_playStoreUrl');
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir Play Store', e);
    }
  }
}
