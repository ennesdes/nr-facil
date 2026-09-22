import 'package:nrfacil/core/models/nr_structure.dart';

/// Entrada achatada para o SliverList do leitor (cabeçalho de seção ou bloco).
sealed class ReaderStructureEntry {
  const ReaderStructureEntry();
}

class ReaderSectionHeaderEntry extends ReaderStructureEntry {
  final NrSection section;
  final bool showTopDivider;

  const ReaderSectionHeaderEntry({
    required this.section,
    required this.showTopDivider,
  });
}

class ReaderBlockEntry extends ReaderStructureEntry {
  final NrSection section;
  final int blockIndex;
  final NrBlock block;

  const ReaderBlockEntry({
    required this.section,
    required this.blockIndex,
    required this.block,
  });
}

/// Achata seções + blocos para lazy build item a item.
List<ReaderStructureEntry> flattenReaderStructure(NrStructure structure) {
  final entries = <ReaderStructureEntry>[];
  for (var i = 0; i < structure.sections.length; i++) {
    final section = structure.sections[i];
    entries.add(
      ReaderSectionHeaderEntry(
        section: section,
        showTopDivider: i == 0,
      ),
    );
    for (var j = 0; j < section.blocks.length; j++) {
      entries.add(
        ReaderBlockEntry(
          section: section,
          blockIndex: j,
          block: section.blocks[j],
        ),
      );
    }
  }
  return entries;
}
