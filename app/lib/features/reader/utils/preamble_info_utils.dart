import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Portaria com data de publicação no D.O.U.
class PreamblePortariaEntry {
  final String portaria;
  final String douDate;

  const PreamblePortariaEntry({
    required this.portaria,
    required this.douDate,
  });

  /// Texto plano para busca e snippets.
  String get plainText {
    if (douDate.isEmpty) return portaria;
    return '$portaria D.O.U. $douDate';
  }
}

/// Publicação original e alterações extraídas do preâmbulo estruturado.
class PreambleInfo {
  final PreamblePortariaEntry? originalPublication;
  final List<PreamblePortariaEntry> amendments;
  final String? vigenciaNote;
  final String? redacaoNote;

  const PreambleInfo({
    this.originalPublication,
    this.amendments = const [],
    this.vigenciaNote,
    this.redacaoNote,
  });

  bool get isEmpty =>
      originalPublication == null &&
      amendments.isEmpty &&
      vigenciaNote == null &&
      redacaoNote == null;

  /// Alteração mais recente (última da lista cronológica).
  PreamblePortariaEntry? get latestAmendment =>
      amendments.isNotEmpty ? amendments.last : null;

  /// Alterações anteriores à mais recente.
  List<PreamblePortariaEntry> get previousAmendments =>
      amendments.length > 1 ? amendments.sublist(0, amendments.length - 1) : const [];

  /// Blocos de preâmbulo com conteúdo visível (exclui sumário).
  int get visibleBlockCount {
    var count = 0;
    if (originalPublication != null || vigenciaNote != null) count++;
    if (amendments.isNotEmpty) count++;
    if (redacaoNote != null) count++;
    return count;
  }
}

final _sumarioPattern = RegExp(
  r'#\s*\*{0,2}\s*(?:SUMÁRIO|Sumário|SUMARIO)\s*\*{0,2}',
  caseSensitive: false,
);

final _douPattern = RegExp(
  r'D\.?\s*O\.?\s*U\.?\s*[:\*\s]*([\d/]+(?:\s+Repub\.\s+[\d/]+)?)',
  caseSensitive: false,
);

final _portariaPattern = RegExp(
  r'Portaria\s+[^\n|#]+',
  caseSensitive: false,
);

final _vigenciaPattern = RegExp(
  r'_\(\s*(Vigência[^)_]+)\)_',
  caseSensitive: false,
);

final _redacaoPattern = RegExp(
  r'_\(\s*((?:(?:Redação|Texto)\s+dad[oa]|Alterad[oa]\s+pela)[^)_]+)\)_',
  caseSensitive: false,
);

final _nrTitlePattern = RegExp(
  r'#\s*\*{0,2}\s*NR\s',
  caseSensitive: false,
);

/// Extrai publicação e alterações de [preamble], com fallback em [manifestEntry].
PreambleInfo parsePreambleInfo(
  NrPreamble preamble, {
  ManifestEntry? manifestEntry,
}) {
  PreamblePortariaEntry? publication;
  final amendments = <PreamblePortariaEntry>[];
  String? vigenciaNote;
  String? redacaoNote;

  for (final block in preamble.blocks) {
    switch (block) {
      case NrParagraphBlock paragraph:
        final text = paragraph.text;
        final beforeSumario = _truncateBeforeSumario(text);

        final vigencia = _vigenciaPattern.firstMatch(beforeSumario);
        if (vigencia != null) {
          vigenciaNote = stripInlineMarkup(vigencia.group(1) ?? '').trim();
        }

        final redacao = _redacaoPattern.firstMatch(beforeSumario);
        if (redacao != null) {
          redacaoNote = stripInlineMarkup(redacao.group(1) ?? '').trim();
        }

        if (!_isNrTitleParagraph(beforeSumario) &&
            _containsPublicationMarker(beforeSumario) &&
            !_looksLikeRedacaoOnly(beforeSumario)) {
          final entry = _parsePortariaFromText(beforeSumario);
          if (entry != null && publication == null) {
            publication = entry;
          }
        }
      case NrTableBlock table:
        _parseTableMarkdown(
          table.markdown,
          onPublication: (entry) {
            publication ??= entry;
          },
          onAmendment: amendments.add,
        );
      default:
        break;
    }
  }

  if (publication == null && manifestEntry != null) {
    publication = _publicationFromManifest(manifestEntry);
  }

  return PreambleInfo(
    originalPublication: publication,
    amendments: amendments,
    vigenciaNote: vigenciaNote,
    redacaoNote: redacaoNote,
  );
}

String _truncateBeforeSumario(String text) {
  final match = _sumarioPattern.firstMatch(text);
  if (match == null) return text;
  return text.substring(0, match.start);
}

bool _containsPublicationMarker(String text) {
  final lower = stripInlineMarkup(text).toLowerCase();
  return lower.contains('publicação') || lower.contains('portaria');
}

bool _looksLikeRedacaoOnly(String text) {
  final trimmed = text.trim();
  if (!trimmed.startsWith('_(')) return false;
  final beforeSumario = _truncateBeforeSumario(trimmed);
  return _redacaoPattern.hasMatch(beforeSumario) &&
      !beforeSumario.toLowerCase().contains('publicação');
}

bool _isNrTitleParagraph(String text) => _nrTitlePattern.hasMatch(text);

String _cleanPortariaText(String portaria) {
  return portaria
      .replaceAll(RegExp(r'\)_$'), '')
      .replaceAll(RegExp(r'^_\('), '')
      .trim();
}

PreamblePortariaEntry? _parsePortariaFromText(String text) {
  final truncated = _truncateBeforeSumario(text);
  final portariaMatch = _portariaPattern.firstMatch(truncated);
  if (portariaMatch == null) return null;

  var portaria = stripInlineMarkup(portariaMatch.group(0) ?? '').trim();
  portaria = portaria.replaceAll(
    RegExp(r'\s*D\.?\s*O\.?\s*U\.?\s*[:\*\s]*[\d/]+(?:\s+Repub\.\s+[\d/]+)?\s*$',
        caseSensitive: false),
    '',
  );
  portaria = portaria.replaceAll(
    RegExp(r'^Publicação\s+D\.?O\.?U\.?\s*', caseSensitive: false),
    '',
  );
  portaria = portaria.replaceAll(
    RegExp(r'^Publicação\s*', caseSensitive: false),
    '',
  );
  portaria = _cleanPortariaText(portaria);
  if (portaria.isEmpty) return null;

  final douMatch = _douPattern.firstMatch(truncated);
  final douDate = douMatch?.group(1)?.trim() ?? '';

  return PreamblePortariaEntry(portaria: portaria, douDate: douDate);
}

void _parseTableMarkdown(
  String markdown, {
  required void Function(PreamblePortariaEntry entry) onPublication,
  required void Function(PreamblePortariaEntry entry) onAmendment,
}) {
  var section = _TableSection.none;

  for (final line in markdown.split('\n')) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('|')) continue;

    final cells = trimmed
        .split('|')
        .map((c) => stripInlineMarkup(c.trim()))
        .where((c) => c.isNotEmpty)
        .toList();

    if (cells.isEmpty) continue;
    if (_isSeparatorRow(cells)) continue;

    if (_isInlinePublicationRow(cells)) {
      final entry = _entryFromTableCells(cells);
      if (entry != null) {
        onPublication(entry);
        section = _TableSection.amendments;
      }
      continue;
    }

    if (_isAlteracoesHeaderRow(cells)) {
      section = _TableSection.amendments;
      continue;
    }
    if (_isPublicationHeaderRow(cells)) {
      section = _TableSection.publication;
      continue;
    }

    final entry = _entryFromTableCells(cells);
    if (entry == null) continue;

    switch (section) {
      case _TableSection.publication:
        onPublication(entry);
        section = _TableSection.amendments;
      case _TableSection.amendments:
        onAmendment(entry);
      case _TableSection.none:
        onAmendment(entry);
    }
  }
}

enum _TableSection { none, publication, amendments }

bool _isSeparatorRow(List<String> cells) {
  return cells.every(
    (c) => c.replaceAll(RegExp(r'[-:]+'), '').trim().isEmpty,
  );
}

bool _isInlinePublicationRow(List<String> cells) {
  final joined = cells.join(' ').toLowerCase();
  return joined.contains('publicação') && joined.contains('portaria');
}

bool _isAlteracoesHeaderRow(List<String> cells) {
  final joined = cells.join(' ').toLowerCase();
  return joined.contains('alterações') || joined.contains('atualizações');
}

bool _isPublicationHeaderRow(List<String> cells) {
  if (_isAlteracoesHeaderRow(cells)) return false;
  final joined = cells.join(' ').toLowerCase();
  if (!joined.contains('publicação')) return false;
  return !joined.contains('portaria');
}

PreamblePortariaEntry? _entryFromTableCells(List<String> cells) {
  if (cells.isEmpty) return null;

  var portariaCell = cells[0];
  var douCell = cells.length > 1 ? cells[1] : '';

  if (portariaCell.toLowerCase().contains('publicação')) {
    final fromCombined = _parsePortariaFromText(portariaCell);
    if (fromCombined != null) {
      portariaCell = fromCombined.portaria;
      if (douCell.isEmpty) douCell = fromCombined.douDate;
    }
  }

  if (douCell.toLowerCase().contains('d.o.u')) {
    final douMatch = _douPattern.firstMatch(douCell);
    douCell = douMatch?.group(1)?.trim() ?? stripInlineMarkup(douCell);
  }

  portariaCell = _cleanPortariaText(portariaCell);
  if (portariaCell.isEmpty) return null;
  if (!portariaCell.toLowerCase().contains('portaria')) return null;

  return PreamblePortariaEntry(
    portaria: portariaCell,
    douDate: douCell.trim(),
  );
}

PreamblePortariaEntry? _publicationFromManifest(ManifestEntry entry) {
  final portaria = entry.portaria?.trim();
  final date = entry.publicadoEm?.trim() ?? '';
  if (portaria == null || portaria.isEmpty) {
    if (date.isEmpty) return null;
    return PreamblePortariaEntry(portaria: 'Publicação', douDate: _formatIsoDate(date));
  }
  return PreamblePortariaEntry(
    portaria: portaria,
    douDate: date.contains('-') ? _formatIsoDate(date) : date,
  );
}

String _formatIsoDate(String iso) {
  try {
    final parts = iso.split('T').first.split('-');
    if (parts.length != 3) return iso;
    final year = parts[0];
    final month = parts[1];
    final day = parts[2];
    final shortYear = year.length >= 2 ? year.substring(year.length - 2) : year;
    return '$day/$month/$shortYear';
  } catch (_) {
    return iso;
  }
}

/// Índice do bloco de preâmbulo para scroll/busca (mantém índices originais).
int preambleBlockIndexFor({
  required NrPreamble preamble,
  required PreambleInfo info,
  required int logicalSection,
}) {
  if (preamble.blocks.isEmpty) return 0;

  switch (logicalSection) {
    case 0:
      return 0;
    case 1:
      if (preamble.blocks.length > 1) return 1;
      return 0;
    case 2:
      if (preamble.blocks.length > 2) return 2;
      if (preamble.blocks.length > 1) return 1;
      return 0;
    default:
      return preamble.blocks.length - 1;
  }
}
