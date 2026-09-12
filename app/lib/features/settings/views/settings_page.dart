import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/constants/app_config.dart';
import 'package:nrfacil/core/constants/official_sources.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/core/widgets/responsive_content.dart';
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
      appBar: AppBar(title: const Text('Ajustes')),
      body: AppScaffoldBody(
        child: ResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              SettingsSectionCard(
                title: 'Aparência',
                description:
                    'Escolha como o app se adapta ao tema do dispositivo.',
                children: [ThemeModeSelector(controller: controller)],
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsSectionCard(
                title: 'Fontes oficiais',
                description:
                    'O conteúdo normativo é de domínio público e provém '
                    'das publicações do governo federal. Consulte as fontes '
                    'abaixo para verificar a informação.',
                children: [
                  for (final source in OfficialSources.entries)
                    SettingsActionTile(
                      icon: Icons.public,
                      title: source.title,
                      subtitle: source.subtitle,
                      trailing: Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => _openExternalUrl(source.url),
                    ),
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
                    onTap: () => _openExternalUrl(AppConfig.privacyPolicyUrl),
                  ),
                  SettingsActionTile(
                    icon: Icons.description_outlined,
                    title: 'Termos de uso',
                    subtitle: 'Condições de uso do aplicativo',
                    trailing: Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => _openExternalUrl(AppConfig.termsOfUseUrl),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const _AboutSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('Não foi possível abrir URL: $url');
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir URL externa', e);
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
            OfficialSources.disclaimer,
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
