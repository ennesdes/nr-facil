import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/utils/app_logger.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/utils/markdown_utils.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_drawer.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_footer.dart';
import 'package:nrfacil/features/reader/views/widgets/markdown_image_builder.dart'
    as image_builder;
import 'package:url_launcher/url_launcher.dart';

/// NRReaderPage — tela principal do leitor de Markdown.
///
/// Exibe:
/// - Conteúdo Markdown com fonte ajustável
/// - Índice lateral (drawer com headings)
/// - Links para PDF original no MTE
/// - Aviso legal fixo
/// - Opções de dark mode e ajuste de fonte na app bar
/// - Suporte a navegação para âncora (seção específica por heading)
class NRReaderPage extends GetView<NRReaderController> {
  final String nrId;
  final String? initialAnchor;

  const NRReaderPage({
    required this.nrId,
    this.initialAnchor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NRReaderController>(
      init: NRReaderController(
        nrId: nrId,
        initialAnchor: initialAnchor,
        contentService: Get.find(),
      ),
      builder: (_) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: ReaderAppBar(
          nrId: nrId,
          onIncreaseFontSize: controller.increaseFontSize,
          onDecreaseFontSize: controller.decreaseFontSize,
          onToggleDarkMode: controller.toggleDarkMode,
          isDarkMode: controller.isDarkMode.value,
          isFavorite: controller.isFavorite,
          onToggleFavorite: controller.toggleFavorite,
        ),
        drawer: ReaderDrawer(
          nrId: nrId,
          index: controller.index.value,
          onNavigate: (headingText) {
            controller.navigateToHeading(headingText);
          },
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(
      () {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.error.value!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        final content = controller.content.value;
        if (content == null || content.isEmpty) {
          return const Center(
            child: Text('Nenhum conteúdo disponível'),
          );
        }

        final isDarkMode = controller.isDarkMode.value;
        final fontSize = controller.fontSize.value;

        // Dividir conteúdo em seções por heading
        final sections = splitMarkdownBySections(content);

        // Se houver initialAnchor, disparar navegação após render
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (initialAnchor != null && initialAnchor!.isNotEmpty) {
            controller.navigateToHeading(initialAnchor!);
          }
        });

        return SingleChildScrollView(
          controller: controller.scrollController,
          child: Column(
            children: [
              // Renderizar seções de conteúdo
              ...sections.map((section) {
                final key = GlobalKey();
                if (section.headingText != null) {
                  // Registrar a chave no controller
                  controller.registerHeadingKey(section.headingText!, key);
                }

                return Padding(
                  key: key,
                  padding: const EdgeInsets.all(16.0),
                  child: MarkdownBody(
                    data: section.markdownContent,
                    selectable: true,
                    softLineBreak: true,
                    styleSheet: _buildMarkdownStyle(
                      context,
                      isDarkMode,
                      fontSize,
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        _launchUrl(href);
                      }
                    },
                    sizedImageBuilder: (config) {
                      return image_builder.NrMarkdownImageBuilder(
                        uri: config.uri,
                        nrId: nrId,
                        title: config.title,
                        alt: config.alt,
                      );
                    },
                  ),
                );
              },
              ),

              // Footer com aviso legal
              ReaderFooter(
                nrId: nrId,
                nrEntry: controller.nrEntry.value,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construir stylesheet customizado para Markdown.
  MarkdownStyleSheet _buildMarkdownStyle(
    BuildContext context,
    bool isDarkMode,
    double fontSize,
  ) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return MarkdownStyleSheet(
      h1: TextStyle(
        fontSize: fontSize + 8,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      h2: TextStyle(
        fontSize: fontSize + 6,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      h3: TextStyle(
        fontSize: fontSize + 4,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      h4: TextStyle(
        fontSize: fontSize + 2,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      h5: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      h6: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      p: TextStyle(
        fontSize: fontSize,
        color: textColor,
        height: 1.6,
      ),
      a: TextStyle(
        fontSize: fontSize,
        color: Colors.blue[isDarkMode ? 300 : 600],
        decoration: TextDecoration.underline,
      ),
      code: TextStyle(
        fontSize: fontSize * 0.9,
        color: isDarkMode ? Colors.amber[300] : Colors.orange[700],
        backgroundColor: isDarkMode ? Color(0xFF2E2E2E) : Colors.orange[50],
      ),
      blockquote: TextStyle(
        fontSize: fontSize,
        color: textColor.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      em: TextStyle(
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        color: textColor,
      ),
      strong: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      del: TextStyle(
        fontSize: fontSize,
        decoration: TextDecoration.lineThrough,
        color: textColor.withValues(alpha: 0.6),
      ),
      listBullet: TextStyle(
        fontSize: fontSize,
        color: textColor,
      ),
    );
  }

  /// Abrir URL externamente via url_launcher.
  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        AppLogger.warning('Não foi possível abrir URL: $urlString');
      }
    } catch (e) {
      AppLogger.error('Erro ao abrir URL', e);
    }
  }
}
