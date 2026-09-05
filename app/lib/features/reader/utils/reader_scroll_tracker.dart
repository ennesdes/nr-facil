import 'package:flutter/material.dart';

/// Âncora de scroll registrada no leitor.
class ReaderScrollAnchor {
  final GlobalKey key;
  final String sectionId;
  final int blockIndex;
  final String? itemNumber;
  final String headingLabel;

  const ReaderScrollAnchor({
    required this.key,
    required this.sectionId,
    required this.headingLabel,
    this.blockIndex = 0,
    this.itemNumber,
  });
}

/// Resultado da detecção de posição de leitura no scroll.
class ReaderScrollPosition {
  final String? sectionId;
  final int? blockIndex;
  final String? itemNumber;
  final String? headingLabel;

  const ReaderScrollPosition({
    this.sectionId,
    this.blockIndex,
    this.itemNumber,
    this.headingLabel,
  });
}

/// Encontra a âncora de leitura: último bloco/seção cuja borda superior
/// já passou pela linha de leitura (topo da viewport + offset).
ReaderScrollPosition findTopmostVisiblePosition({
  required List<ReaderScrollAnchor> anchors,
  double viewportTopOffset = 120,
}) {
  ReaderScrollAnchor? lastPassed;
  var lastPassedDy = double.negativeInfinity;
  ReaderScrollAnchor? firstBelow;
  var firstBelowDy = double.infinity;

  for (final anchor in anchors) {
    final context = anchor.key.currentContext;
    if (context == null) continue;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) continue;

    final dy = box.localToGlobal(Offset.zero).dy;

    if (dy <= viewportTopOffset) {
      final isBetter = dy > lastPassedDy ||
          (dy >= lastPassedDy - 1 &&
              anchor.blockIndex > (lastPassed?.blockIndex ?? -1) &&
              anchor.sectionId == lastPassed?.sectionId);
      if (lastPassed == null || isBetter) {
        lastPassed = anchor;
        lastPassedDy = dy;
      }
    } else if (dy < firstBelowDy) {
      firstBelow = anchor;
      firstBelowDy = dy;
    }
  }

  // Quando o anchor recém-passado já saiu de vista (ex.: fim do documento,
  // onde o scroll fica travado antes do alinhamento ideal), prefere o
  // próximo anchor se ele estiver mais perto da linha de leitura — evita
  // apontar para um item que não está mais visível na tela.
  ReaderScrollAnchor? best;
  if (lastPassed != null && firstBelow != null) {
    final passedDistance = viewportTopOffset - lastPassedDy;
    final belowDistance = firstBelowDy - viewportTopOffset;
    best = belowDistance < passedDistance ? firstBelow : lastPassed;
  } else {
    best = lastPassed ?? firstBelow;
  }
  if (best == null) {
    return const ReaderScrollPosition();
  }

  return ReaderScrollPosition(
    sectionId: best.sectionId,
    blockIndex: best.blockIndex,
    itemNumber: best.itemNumber,
    headingLabel: best.headingLabel,
  );
}
