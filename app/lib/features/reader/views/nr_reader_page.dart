import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_markdown_fallback_body.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_reader_search_sheet.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_structured_body.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';
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
    return Obx(() => _buildScaffold(context));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: ReaderAppBar(
        nrId: nrId,
        onOpenSearch: () => NrReaderSearchSheet.show(
          context: context,
          controller: controller,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error.value != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
        isDarkMode: false,
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
      isDarkMode: false,
      scrollController: controller.scrollController,
      onRegisterHeadingKey: controller.registerHeadingKey,
      banner: banner,
    );
  }
}
