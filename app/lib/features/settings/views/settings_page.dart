import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tela de ajustes do app — tema e informações.
class SettingsPage extends GetView<ThemeController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        elevation: 1,
      ),
      body: AppScaffoldBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
          _ThemeSection(controller: controller),
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          const _LegalSection(),
          const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
          const _AboutSection(),
        ],
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final ThemeController controller;

  const _ThemeSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aparência',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Escolha como o app se adapta ao tema do dispositivo.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Escuro'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {controller.themeMode.value},
              onSelectionChanged: (selection) {
                controller.setThemeMode(selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.privacy_tip_outlined, color: colorScheme.primary),
            title: const Text('Política de privacidade'),
            subtitle: const Text('Como tratamos seus dados'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _openPrivacyPolicy(),
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final uri = Uri.parse(AppConfig.privacyPolicyUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning(
          'Não foi possível abrir política de privacidade: '
          '${AppConfig.privacyPolicyUrl}',
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir política de privacidade', e);
    }
  }
}

class _AboutSection extends StatefulWidget {
  const _AboutSection();

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  String _version = '—';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sobre',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('NR Fácil'),
            subtitle: Text('Versão $_version'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Este aplicativo disponibiliza conteúdo público oficial das '
              'Normas Regulamentadoras do Ministério do Trabalho e Emprego. '
              'O conteúdo não substitui a consulta às publicações oficiais '
              'no portal gov.br.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
