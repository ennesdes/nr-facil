import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Retângulo aproximado da linha que contém [matchStart] dentro de um bloco.
Rect matchRectInBlock({
  required double maxWidth,
  required String plainText,
  required int matchStart,
  required double fontSize,
  double lineHeight = 1.6,
}) {
  final width = maxWidth > 0 ? maxWidth : 300.0;
  final lineHeightPx = fontSize * lineHeight;

  if (plainText.isEmpty || matchStart < 0) {
    return Rect.fromLTWH(0, 0, width, lineHeightPx);
  }

  final style = TextStyle(fontSize: fontSize, height: lineHeight);
  final painter = TextPainter(
    text: TextSpan(text: plainText, style: style),
    textDirection: TextDirection.ltr,
    maxLines: null,
  )..layout(maxWidth: width);

  final safeOffset = matchStart.clamp(0, plainText.length);
  final caret = painter.getOffsetForCaret(
    TextPosition(offset: safeOffset),
    Rect.zero,
  );

  return Rect.fromLTWH(
    0,
    caret.dy,
    width,
    lineHeightPx,
  );
}

/// Rola o [scrollController] para deixar a ocorrência em [matchStart] no topo
/// da área visível do leitor.
bool scrollToSearchMatch({
  required BuildContext context,
  required ScrollController scrollController,
  required int matchStart,
  required String plainText,
  required double fontSize,
  double lineHeight = 1.6,
  Duration duration = const Duration(milliseconds: 350),
  Curve curve = Curves.easeInOut,
}) {
  final renderObject = context.findRenderObject();
  if (renderObject == null || !scrollController.hasClients) return false;
  if (renderObject is! RenderBox || !renderObject.hasSize) return false;

  final viewport = RenderAbstractViewport.of(renderObject);
  final box = renderObject;
  final matchRect = matchRectInBlock(
    maxWidth: box.size.width,
    plainText: plainText,
    matchStart: matchStart,
    fontSize: fontSize,
    lineHeight: lineHeight,
  );

  final reveal = viewport.getOffsetToReveal(renderObject, 0.0, rect: matchRect);
  final position = scrollController.position;
  final target =
      reveal.offset.clamp(position.minScrollExtent, position.maxScrollExtent);

  if ((position.pixels - target).abs() < 1) return true;

  position.animateTo(target, duration: duration, curve: curve);
  return true;
}
