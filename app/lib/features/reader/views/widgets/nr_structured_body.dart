import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_preamble_section.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_reader_header.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_section_card.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_footer.dart';
import 'package:nrfacil/core/models/manifest.dart';

/// Corpo estruturado do leitor com SliverList lazy e seções recolhíveis.
class NrStructuredBody extends StatelessWidget {
  final NrStructure structure;
  final ManifestEntry? nrEntry;
  final String nrId;
  final double fontSize;
  final bool isDarkMode;
  final ScrollController scrollController;
  final GlobalKey Function(String sectionId) sectionKeyFor;
  final Widget? banner;

  const NrStructuredBody({
    required this.structure,
    required this.nrEntry,
    required this.nrId,
    required this.fontSize,
    required this.isDarkMode,
    required this.scrollController,
    required this.sectionKeyFor,
    this.banner,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NRReaderController>();
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50;

    return ColoredBox(
      color: bgColor,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (banner != null) SliverToBoxAdapter(child: banner),
          Obx(
            () => SliverToBoxAdapter(
              child: NrReaderHeader(
                title: structure.title.isNotEmpty
                    ? structure.title
                    : (nrEntry?.title ?? nrId),
                nrEntry: nrEntry,
                isDarkMode: isDarkMode,
                highlightQuery: controller.activeHighlightQuery.value,
              ),
            ),
          ),
          Obx(
            () => SliverToBoxAdapter(
              child: NrPreambleSection(
                preamble: structure.preamble,
                fontSize: fontSize,
                isDarkMode: isDarkMode,
                nrId: nrId,
                isExpanded: controller.isPreambleExpanded.value,
                highlightQuery: controller.activeHighlightQuery.value,
                highlightBlockIndex: controller.highlightSectionId.value ==
                        'preamble'
                    ? controller.highlightBlockIndex.value
                    : null,
                blockKeyFor: controller.blockKeyFor,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${structure.sections.length} seções — toque para expandir',
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ),
          Obx(
            () {
              final highlightSectionId = controller.highlightSectionId.value;
              final highlightBlockIndex = controller.highlightBlockIndex.value;
              final highlightQuery = controller.activeHighlightQuery.value;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = structure.sections[index];
                    final expanded =
                        controller.expandedSectionIds.contains(section.id);
                    final sectionIsTarget =
                        highlightSectionId == section.id;

                    return KeyedSubtree(
                      key: sectionKeyFor(section.id),
                      child: NrSectionCard(
                        section: section,
                        fontSize: fontSize,
                        isDarkMode: isDarkMode,
                        nrId: nrId,
                        isExpanded: expanded,
                        highlightQuery: highlightQuery,
                        highlightBlockIndex:
                            sectionIsTarget ? highlightBlockIndex : null,
                        blockKeyFor: controller.blockKeyFor,
                        onExpansionChanged: (value) {
                          if (value) {
                            controller.expandSection(section.id);
                          } else {
                            controller.toggleSectionExpanded(section.id);
                          }
                        },
                      ),
                    );
                  },
                  childCount: structure.sections.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: ReaderFooter(
              nrId: nrId,
              nrEntry: nrEntry,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
    );
  }
}
