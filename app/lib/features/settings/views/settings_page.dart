import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/features/settings/views/widgets/settings_action_tile.dart';
import 'package:nrfacil/features/settings/views/widgets/settings_section_card.dart';
import 'package:nrfacil/features/settings/views/widgets/theme_mode_selector.dart';
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
      ),
      body: AppScaffoldBody(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SettingsSectionCard(
              title: 'Aparência',
              description:
                  'Escolha como o app se adapta ao tema do dispositivo.',
              children: [
                ThemeModeSelector(controller: controller),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsSectionCard(
              title: 'Legal',
              children: [
                SettingsActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Política de privacidade',
                  subtitle: 'Como tratamos seus dados',
                  trailing: Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTap: _openPrivacyPolicy,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const _AboutSection(),
          ],
        ),
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
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = _formatVersionLabel(info);
    });
  }

  String _formatVersionLabel(PackageInfo info) {
    final build = info.buildNumber.trim();
    if (build.isEmpty) {
      return info.version;
    }
    return '${info.version} ($build)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final versionLabel = _versionLabel;

    return SettingsSectionCard(
      title: 'Sobre',
      children: [
        SettingsInfoTile(
          icon: Icons.info_outline,
          title: 'NR Fácil',
          subtitle: versionLabel == null
              ? 'Carregando versão…'
              : 'Versão $versionLabel',
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            'Este aplicativo disponibiliza conteúdo público oficial das '
            'Normas Regulamentadoras do Ministério do Trabalho e Emprego. '
            'O conteúdo não substitui a consulta às publicações oficiais '
            'no portal gov.br.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
