/// IDs de semântica para testes E2E do bloco Leitura (reader).
///
/// Cobre: página do leitor, app bar (navegação, busca, índice, favoritar),
/// controle de tamanho de fonte, rodapé (link PDF, disclaimer legal) e
/// página de NR revogada.
class ReaderSemanticsIds {
  // Tela do leitor
  static const String readerPageRoot = 'reader_page_root';

  // App bar do leitor
  static const String backButton = 'reader_back_button';
  static const String searchButton = 'reader_search_button';
  static const String indexButton = 'reader_index_button';
  static const String favoriteButton = 'reader_favorite_button';

  // Controle de tamanho de fonte
  static const String fontSizeDecrease = 'reader_font_size_decrease';
  static const String fontSizeIncrease = 'reader_font_size_increase';

  // Rodapé
  static const String viewPdfButton = 'reader_view_pdf_button';
  static const String disclaimerText = 'reader_disclaimer_text';

  // Página de NR revogada
  static const String revokedNrPageRoot = 'revoked_nr_page_root';
  static const String revokedViewPdfButton = 'revoked_view_pdf_button';
  static const String revokedOpenSuccessor = 'revoked_open_successor';
}
