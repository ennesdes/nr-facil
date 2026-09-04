import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_markdown_fallback_body.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_reader_search_sheet.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_structured_body.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_drawer.dart';
import 'package:nrfacil/features/reader/views/widgets/update_banner.dart';

/// NRReaderPage — leitor estruturado de NRs com fallback Markdown.
class NRReaderPage extends GetView<NRReaderController> {
  final String nrId;

  const NRReaderPage({
    required this.nrId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild ao alternar tema global ou estado do controller.
      Get.find<ThemeController>().themeMode.value;
      return _buildScaffold(context);
    });
  }

  Widget _buildScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: controller.scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: ReaderAppBar(
        nrId: nrId,
        isFavorite: controller.isFavorite,
        isDarkMode: isDark,
        onOpenIndex: () => controller.scaffoldKey.currentState?.openDrawer(),
        onOpenSearch: () => NrReaderSearchSheet.show(
          context: context,
          controller: controller,
        ),
        onToggleFavorite: controller.toggleFavorite,
        onIncreaseFontSize: controller.increaseFontSize,
        onDecreaseFontSize: controller.decreaseFontSize,
        onToggleDarkMode: controller.toggleDarkMode,
      ),
      drawer: ReaderDrawer(
        structure: controller.structure.value,
        legacyIndex: controller.index.value,
        onNavigate: controller.navigateToSection,
        onNavigateToItem: controller.navigateToItemNumber,
        onExpandAll: controller.expandAllSections,
        onCollapseAll: controller.collapseAllSections,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value || controller.isDownloading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error.value != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                controller.error.value!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.downloadNrContent,
                icon: const Icon(Icons.download),
                label: const Text('Baixar agora'),
              ),
            ],
          ),
        ),
      );
    }

    final content = controller.content.value;
    if (content == null || content.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo disponível'));
    }

    final fontSize = controller.fontSize.value;
    final banner = controller.showUpdateBanner.value
        ? const UpdateBanner()
        : null;

    if (controller.useStructuredView) {
      return NrStructuredBody(
        structure: controller.structure.value!,
        nrEntry: controller.nrEntry.value,
        nrId: nrId,
        fontSize: fontSize,
        scrollController: controller.scrollController,
        sectionKeyFor: controller.sectionKeyFor,
        banner: banner,
      );
    }

    return NrMarkdownFallbackBody(
      content: content,
      nrId: nrId,
      nrEntry: controller.nrEntry.value,
      fontSize: fontSize,
      scrollController: controller.scrollController,
      onRegisterHeadingKey: controller.registerHeadingKey,
      banner: banner,
    );
  }
}
