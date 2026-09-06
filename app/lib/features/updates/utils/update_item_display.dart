import 'package:nrfacil/core/models/app_meta.dart';

/// Conteúdo normalizado de um [UpdateItem] para exibição na UI.
class UpdateItemDisplay {
  final String item;
  final String tipo;
  final List<String> antes;
  final List<String> depois;
  final List<String> conteudo;

  const UpdateItemDisplay({
    required this.item,
    required this.tipo,
    this.antes = const [],
    this.depois = const [],
    this.conteudo = const [],
  });

  factory UpdateItemDisplay.fromUpdateItem(UpdateItem item) {
    final tipo = item.tipo.toLowerCase();

    if (tipo == 'alterado') {
      final parsed = _resolveAlteradoTexts(item);
      return UpdateItemDisplay(
        item: item.item,
        tipo: tipo,
        antes: fullTextBullets(parsed.antes),
        depois: fullTextBullets(parsed.depois),
      );
    }

    return UpdateItemDisplay(
      item: item.item,
      tipo: tipo,
      conteudo: fullTextBullets(item.resumo),
    );
  }

  bool get isAlterado => tipo == 'alterado';
  bool get isNovo => tipo == 'novo';
  bool get isRemovido => tipo == 'removido';
}

({String antes, String depois}) _resolveAlteradoTexts(UpdateItem item) {
  final explicitAntes = item.antes?.trim();
  final explicitDepois = item.depois?.trim();
  if ((explicitAntes?.isNotEmpty ?? false) ||
      (explicitDepois?.isNotEmpty ?? false)) {
    return (antes: explicitAntes ?? '', depois: explicitDepois ?? '');
  }

  return _parseLegacyAlteradoResumo(item.resumo);
}

({String antes, String depois}) _parseLegacyAlteradoResumo(String resumo) {
  final trimmed = resumo.trim();
  if (trimmed.isEmpty) {
    return (antes: '', depois: '');
  }

  final arrowIndex = trimmed.indexOf('→');
  if (arrowIndex == -1) {
    return (antes: trimmed, depois: '');
  }

  final left = trimmed.substring(0, arrowIndex).trim();
  final right = trimmed.substring(arrowIndex + 1).trim();

  final antes = _stripLabelPrefix(left, 'antes:');
  final depois = _stripLabelPrefix(right, 'depois:');

  return (antes: antes, depois: depois);
}

String _stripLabelPrefix(String value, String prefix) {
  final normalized = value.trim();
  if (normalized.toLowerCase().startsWith(prefix)) {
    return normalized.substring(prefix.length).trim();
  }
  return normalized;
}

String cleanUpdateSnippet(String text) {
  var value = text.trim();
  while (value.startsWith('…') && value.endsWith('…') && value.length > 2) {
    value = value.substring(1, value.length - 1).trim();
  }
  return value;
}

/// Um único bloco com o texto integral do item (sem fatiar por `|` ou diff).
List<String> fullTextBullets(String text) {
  final cleaned = cleanUpdateSnippet(text);
  if (cleaned.isEmpty) return const [];
  return [cleaned];
}
