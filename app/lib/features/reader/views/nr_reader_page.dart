import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_system_ui.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_markdown_fallback_body.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_structured_body.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_drawer.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_search_bar.dart';
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
      Get.find<ThemeController>().themeMode.value;
      return _buildScaffold(context);
    });
  }

  Widget _buildScaffold(BuildContext context) {
    final readerSurface = context.readerSurfaceColor;

    return AppSystemUiScope(
      surface: readerSurface,
      child: Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: readerSurface,
      appBar: ReaderAppBar(
        nrId: nrId,
        isFavorite: controller.isFavorite,
        fontSize: controller.fontSize.value,
        onBack: () => Get.back(),
        onOpenIndex: () => controller.scaffoldKey.currentState?.openDrawer(),
        onOpenSearch: controller.openSearch,
        onToggleFavorite: controller.toggleFavorite,
        onIncreaseFontSize: controller.increaseFontSize,
        onDecreaseFontSize: controller.decreaseFontSize,
      ),
      drawer: Obx(
        () => ReaderDrawer(
          structure: controller.structure.value,
          legacyIndex: controller.index.value,
          currentSectionId: controller.currentSectionId.value,
          currentItemNumber: controller.currentItemNumber.value,
          currentPositionLabel: controller.currentPositionLabel,
          progressPercent: controller.readingProgressPercent.value,
          onNavigate: controller.navigateToSection,
          onNavigateToItem: controller.navigateToItemNumber,
        ),
      ),
      body: AppScaffoldBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => controller.isSearchOpen.value
                  ? ReaderSearchBar(controller: controller)
                  : const SizedBox.shrink(),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value || controller.isDownloading.value) {
      return const ReaderBodyShimmer();
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
