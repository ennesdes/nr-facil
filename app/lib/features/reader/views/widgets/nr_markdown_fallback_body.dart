import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/utils/markdown_utils.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';
import 'package:nrfacil/features/reader/views/widgets/markdown_image_builder.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_footer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fallback: renderiza Markdown quando structure.json não está disponível.
class NrMarkdownFallbackBody extends StatelessWidget {
  final String content;
  final String nrId;
  final ManifestEntry? nrEntry;
  final double fontSize;
  final bool isDarkMode;
  final ScrollController scrollController;
  final void Function(String headingText, GlobalKey key) onRegisterHeadingKey;
  final Widget? banner;

  const NrMarkdownFallbackBody({
    required this.content,
    required this.nrId,
    required this.nrEntry,
    required this.fontSize,
    required this.isDarkMode,
    required this.scrollController,
    required this.onRegisterHeadingKey,
    this.banner,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NRReaderController>();
    final sections = splitMarkdownBySections(content);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Obx(() {
      final highlightQuery = controller.activeHighlightQuery.value;
      final useHighlight =
          highlightQuery != null && highlightQuery.trim().isNotEmpty;

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

              if (useHighlight) {
                return Padding(
                  key: key,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.headingText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HighlightedText(
                            text: section.headingText!,
                            highlight: highlightQuery,
                            style: TextStyle(
                              fontSize: fontSize + 4,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      HighlightedText(
                        text: stripInlineMarkup(section.markdownContent),
                        highlight: highlightQuery,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                key: key,
                padding: const EdgeInsets.all(16),
                child: MarkdownBody(
                  data: section.markdownContent,
                  selectable: true,
                  softLineBreak: true,
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                      fontSize: fontSize + 8,
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
                  ),
                  onTapLink: (text, href, title) {
                    if (href != null) launchUrl(Uri.parse(href));
                  },
                  sizedImageBuilder: (config) => NrMarkdownImageBuilder(
                    uri: config.uri,
                    nrId: nrId,
                    title: config.title,
                    alt: config.alt,
                  ),
                ),
              );
            }),
            ReaderFooter(
              nrId: nrId,
              nrEntry: nrEntry,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      );
    });
  }
}
