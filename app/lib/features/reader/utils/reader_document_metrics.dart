import 'dart:math' as math;

import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Altura estimada do cabeçalho, chip e preâmbulo colapsado acima das seções.
const double kReaderTopContentHeight = 380.0;

/// Altura estimada do rodapé legal + padding inferior de scroll.
const double kReaderFooterHeight = 200.0 + kReaderBottomScrollPadding;

/// Altura típica de imagem/tabela renderizada como PNG no leitor.
const double kReaderImageBlockHeight = 220.0;

/// Estima a altura de um bloco normativo para cálculo de progresso/scroll.
double estimateBlockHeight(NrBlock block) {
  if (block is NrItemBlock) {
    final textLen = stripInlineMarkup(block.text).length;
    final lines = (textLen / 55).ceil().clamp(1, 24);
    return 36.0 + lines * 26.0;
  }
  if (block is NrTableBlock) return 120.0;
  if (block is NrImageBlock) return kReaderImageBlockHeight;
  if (block is NrListBlock) return 48.0 + block.items.length * 28.0;
  if (block is NrParagraphBlock || block is NrNoteBlock) {
    final text = block is NrParagraphBlock
        ? block.text
        : (block as NrNoteBlock).text;
    final textLen = stripInlineMarkup(text).length;
    final lines = (textLen / 55).ceil().clamp(1, 16);
    return 24.0 + lines * 26.0;
  }
  return 56.0;
}

/// Estima a altura total de uma seção (título + blocos).
double estimateSectionHeight(NrSection section) {
  var height = 72.0;
  for (final block in section.blocks) {
    height += estimateBlockHeight(block);
  }
  return height;
}

/// Estima a altura total do documento no leitor estruturado.
double estimateDocumentHeight(NrStructure structure) {
  var height = kReaderTopContentHeight;
  for (final section in structure.sections) {
    height += estimateSectionHeight(section);
  }
  height += kReaderFooterHeight;
  return height;
}

/// Offset estimado até o início de [blockIndex] em [sectionId].
double estimateProgressOffset({
  required NrStructure structure,
  required String sectionId,
  required int blockIndex,
}) {
  var offset = kReaderTopContentHeight;

  for (final section in structure.sections) {
    offset += 72.0;
    if (section.id == sectionId) {
      final limit = blockIndex.clamp(0, section.blocks.length);
      for (var i = 0; i < limit; i++) {
        offset += estimateBlockHeight(section.blocks[i]);
      }
      return offset;
    }
    for (final block in section.blocks) {
      offset += estimateBlockHeight(block);
    }
  }

  return offset;
}

/// Extent estável para fallback baseado em scroll.
double stableScrollExtent({
  required double maxScrollExtent,
  required double estimatedDocumentHeight,
}) {
  if (maxScrollExtent <= 0) return estimatedDocumentHeight;
  if (estimatedDocumentHeight <= 0) return maxScrollExtent;
  return math.max(maxScrollExtent, estimatedDocumentHeight);
}

/// Progresso baseado na posição na estrutura (imune ao lazy loading).
int computeStructureReadingProgressPercent({
  required NrStructure structure,
  required String sectionId,
  required int blockIndex,
  required double scrollPixels,
  required double maxScrollExtent,
  double endTolerance = 4,
}) {
  if (maxScrollExtent > 0 && scrollPixels >= maxScrollExtent - endTolerance) {
    return 100;
  }

  final total = estimateDocumentHeight(structure);
  if (total <= 0) return 0;

  final offset = estimateProgressOffset(
    structure: structure,
    sectionId: sectionId,
    blockIndex: blockIndex,
  );

  return ((offset / total) * 100).round().clamp(0, 100);
}

/// Fallback por scroll quando a estrutura não está disponível.
int computeReadingProgressPercent({
  required double scrollPixels,
  required double maxScrollExtent,
  required double estimatedDocumentHeight,
  double endTolerance = 4,
}) {
  if (maxScrollExtent > 0 && scrollPixels >= maxScrollExtent - endTolerance) {
    return 100;
  }

  final extent = stableScrollExtent(
    maxScrollExtent: maxScrollExtent,
    estimatedDocumentHeight: estimatedDocumentHeight,
  );
  if (extent <= 0) {
    return scrollPixels > 0 ? 100 : 0;
  }

  return ((scrollPixels / extent) * 100).round().clamp(0, 100);
}
