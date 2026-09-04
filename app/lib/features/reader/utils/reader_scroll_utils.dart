import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Restaura a posição de scroll proporcionalmente quando o conteúdo mudou de tamanho.
double resolveScrollOffset({
  required double savedPosition,
  required double savedMaxExtent,
  required double currentMaxExtent,
}) {
  if (currentMaxExtent <= 0) return savedPosition;
  if (savedMaxExtent <= 0) {
    return savedPosition.clamp(0.0, currentMaxExtent);
  }
  final ratio = (savedPosition / savedMaxExtent).clamp(0.0, 1.0);
  return ratio * currentMaxExtent;
}

/// Rola até um widget identificado por [key] usando o [scrollController] informado.
bool scrollToWidgetKey({
  required GlobalKey key,
  required ScrollController scrollController,
  double alignment = 0.08,
  Duration duration = const Duration(milliseconds: 350),
  Curve curve = Curves.easeInOut,
}) {
  final context = key.currentContext;
  if (context == null || !scrollController.hasClients) return false;

  final renderObject = context.findRenderObject();
  if (renderObject == null ||
      renderObject is! RenderBox ||
      !renderObject.hasSize) {
    return false;
  }

  final viewport = RenderAbstractViewport.maybeOf(renderObject);
  if (viewport == null) return false;

  final reveal = viewport.getOffsetToReveal(renderObject, alignment);
  final position = scrollController.position;
  final target =
      reveal.offset.clamp(position.minScrollExtent, position.maxScrollExtent);

  if ((position.pixels - target).abs() < 2) return true;

  position.animateTo(target, duration: duration, curve: curve);
  return true;
}

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
