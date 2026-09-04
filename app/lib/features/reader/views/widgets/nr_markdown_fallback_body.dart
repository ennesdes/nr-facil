import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/utils/markdown_utils.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_footer.dart';
import 'package:nrfacil/features/reader/views/widgets/searchable_markdown_body.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fallback: renderiza Markdown quando structure.json não está disponível.
class NrMarkdownFallbackBody extends StatelessWidget {
  final String content;
  final String nrId;
  final ManifestEntry? nrEntry;
  final double fontSize;
  final ScrollController scrollController;
  final void Function(String headingText, GlobalKey key) onRegisterHeadingKey;
  final Widget? banner;

  const NrMarkdownFallbackBody({
    required this.content,
    required this.nrId,
    required this.nrEntry,
    required this.fontSize,
    required this.scrollController,
    required this.onRegisterHeadingKey,
    this.banner,
    super.key,
  });

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

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
      p: TextStyle(
        fontSize: fontSize,
        color: textColor,
        height: 1.6,
      ),
      strong: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      listBullet: TextStyle(
        fontSize: fontSize,
        color: textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NRReaderController>();
    final sections = splitMarkdownBySections(content);

    return Obx(() {
      final highlightQuery = controller.activeHighlightQuery.value;

      return SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            ?banner,
            ...sections.map((section) {
              final key = GlobalKey();
              if (section.headingText != null) {
                onRegisterHeadingKey(section.headingText!, key);
              }

              return Padding(
                key: key,
                padding: const EdgeInsets.all(16),
                child: SearchableMarkdownBody(
                  data: section.markdownContent,
                  highlightQuery: highlightQuery,
                  styleSheet: _styleSheet(context),
                  nrId: nrId,
                  onTapLink: (text, href, title) {
                    if (href != null) launchUrl(Uri.parse(href));
                  },
                ),
              );
            }),
            ReaderFooter(
              nrId: nrId,
              nrEntry: nrEntry,
            ),
          ],
        ),
      );
    });
  }
}
