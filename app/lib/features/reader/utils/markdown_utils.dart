/// Modelo para uma seção de markdown (heading + body)
class MarkdownSection {
  final String? headingText; // null se for conteúdo inicial sem heading
  final String markdownContent; // markdown da seção (inclui heading se existir)

  MarkdownSection({
    required this.headingText,
    required this.markdownContent,
  });
}

/// Dividir conteúdo markdown em seções por heading.
/// Cada seção começa com um heading (linhas com `#`) ou é conteúdo inicial.
/// Retorna lista de seções com heading extraído.
List<MarkdownSection> splitMarkdownBySections(String content) {
  final sections = <MarkdownSection>[];
  final lines = content.split('\n');

  String currentSection = '';
  String? currentHeading;

  for (final line in lines) {
    // Detectar heading (linhas que começam com #)
    if (line.startsWith('#') && line.trim().startsWith(RegExp(r'^#+\s'))) {
      // Salvar seção anterior se existir
      if (currentSection.isNotEmpty) {
        sections.add(
          MarkdownSection(
            headingText: currentHeading,
            markdownContent: currentSection.trim(),
          ),
        );
      }

      // Extrair texto do heading (remover # e espaços)
      currentHeading = line.replaceFirst(RegExp(r'^#+\s'), '').trim();
      currentSection = line; // Incluir o heading na próxima seção
    } else {
      currentSection += '\n$line';
    }
  }

  // Salvar última seção
  final trimmedSection = currentSection.trim();
  if (trimmedSection.isNotEmpty) {
    sections.add(
      MarkdownSection(
        headingText: currentHeading,
        markdownContent: trimmedSection,
      ),
    );
  }

  return sections;
}
