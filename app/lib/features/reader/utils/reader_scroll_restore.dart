/// Utilitários para restaurar posição de leitura em listas lazy.
library;

/// Razão efetiva de scroll (0.0–1.0) a partir dos campos salvos no histórico.
double effectiveScrollRatioFromEntry({
  double? scrollRatio,
  double scrollPosition = 0,
  double scrollMaxExtent = 0,
}) {
  if (scrollRatio != null && scrollRatio > 0) {
    return scrollRatio.clamp(0.0, 1.0);
  }
  if (scrollMaxExtent > 0 && scrollPosition > 0) {
    return (scrollPosition / scrollMaxExtent).clamp(0.0, 1.0);
  }
  return 0;
}

/// Offset alvo para uma razão e extent atual.
double targetOffsetForScrollRatio(double ratio, double maxScrollExtent) {
  if (maxScrollExtent <= 0 || ratio <= 0) return 0;
  return ratio.clamp(0.0, 1.0) * maxScrollExtent;
}

/// Indica se a restauração por razão pode ser considerada concluída.
bool isScrollRatioRestoreComplete({
  required double pixels,
  required double maxScrollExtent,
  required double ratio,
  required int stableExtentFrames,
  double tolerance = 56,
  int minStableFrames = 2,
}) {
  if (maxScrollExtent <= 1) return false;
  final target = targetOffsetForScrollRatio(ratio, maxScrollExtent);
  final atTarget = (pixels - target).abs() <= tolerance;
  return atTarget && stableExtentFrames >= minStableFrames;
}

/// Atualiza contagem de frames com extent estável (lazy list parou de crescer).
int nextStableExtentFrameCount({
  required double? previousMaxExtent,
  required double currentMaxExtent,
  required int currentStableFrames,
}) {
  if (previousMaxExtent != null &&
      (currentMaxExtent - previousMaxExtent).abs() < 1) {
    return currentStableFrames + 1;
  }
  return 0;
}
