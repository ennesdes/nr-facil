import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_preamble_section.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_reader_header.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_section_card.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_footer.dart';

/// Corpo estruturado do leitor com SliverList lazy e seções recolhíveis.
class NrStructuredBody extends StatelessWidget {
  final NrStructure structure;
  final ManifestEntry? nrEntry;
  final String nrId;
  final double fontSize;
  final ScrollController scrollController;
  final GlobalKey Function(String sectionId) sectionKeyFor;
  final Widget? banner;

  const NrStructuredBody({
    required this.structure,
    required this.nrEntry,
    required this.nrId,
    required this.fontSize,
    required this.scrollController,
    required this.sectionKeyFor,
    this.banner,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NRReaderController>();
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
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
                highlightQuery: controller.activeHighlightQuery.value,
              ),
            ),
          ),
          Obx(
            () => SliverToBoxAdapter(
              child: NrPreambleSection(
                preamble: structure.preamble,
                fontSize: fontSize,
                nrId: nrId,
                isExpanded: controller.isPreambleExpanded.value,
                highlightQuery: controller.activeHighlightQuery.value,
                blockKeyFor: controller.blockKeyFor,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${structure.sections.length} seções — toque para expandir',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: fontSize - 2,
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          Obx(
            () {
              final highlightQuery = controller.activeHighlightQuery.value;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = structure.sections[index];
                    final expanded =
                        controller.expandedSectionIds.contains(section.id);

                    return KeyedSubtree(
                      key: sectionKeyFor(section.id),
                      child: NrSectionCard(
                        section: section,
                        fontSize: fontSize,
                        nrId: nrId,
                        isExpanded: expanded,
                        highlightQuery: highlightQuery,
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
            ),
          ),
        ],
      ),
    );
  }
}
