import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_preamble_section.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_reader_header.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_section_block.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_continue_chip.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_footer.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_position_indicator.dart';

/// Corpo estruturado do leitor com SliverList lazy e leitura contínua.
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
    final readerBg = context.readerSurfaceColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: readerBg,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              if (banner != null) SliverToBoxAdapter(child: banner),
              Obx(
                () {
                  final label = controller.continueLabel;
                  if (!controller.showContinueChip.value || label == null) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: ReaderContinueChip(
                      label: label,
                      onTap: controller.continueFromSavedPosition,
                      onDismiss: controller.dismissContinueChip,
                    ),
                  );
                },
              ),
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
                    nrEntry: nrEntry,
                    fontSize: fontSize,
                    nrId: nrId,
                    isExpanded: controller.isPreambleExpanded.value,
                    onExpansionChanged: controller.setPreambleExpanded,
                    highlightQuery: controller.activeHighlightQuery.value,
                    blockKeyFor: controller.blockKeyFor,
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

                        return KeyedSubtree(
                          key: sectionKeyFor(section.id),
                          child: NrSectionBlock(
                            section: section,
                            fontSize: fontSize,
                            nrId: nrId,
                            highlightQuery: highlightQuery,
                            blockKeyFor: controller.blockKeyFor,
                            showTopDivider: index == 0,
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
              const SliverToBoxAdapter(
                child: SizedBox(height: kReaderBottomScrollPadding),
              ),
            ],
          ),
        ),
        Obx(
          () {
            if (!controller.showPositionIndicator.value) {
              return const SizedBox.shrink();
            }
            return ReaderPositionIndicator(
              itemLabel: controller.currentPositionLabel,
              progressPercent: controller.readingProgressPercent.value,
              onTap: () =>
                  controller.scaffoldKey.currentState?.openDrawer(),
            );
          },
        ),
      ],
    );
  }
}
