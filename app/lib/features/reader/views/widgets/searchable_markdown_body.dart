import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nrfacil/features/reader/utils/markdown_highlight_utils.dart';
import 'package:nrfacil/features/reader/views/widgets/markdown_image_builder.dart';

/// MarkdownBody com destaque inline do termo de busca, preservando formatação.
class SearchableMarkdownBody extends StatelessWidget {
  final String data;
  final String? highlightQuery;
  final MarkdownStyleSheet styleSheet;
  final bool softLineBreak;
  final MarkdownSizedImageBuilder? sizedImageBuilder;
  final MarkdownTapLinkCallback? onTapLink;
  final String? nrId;

  const SearchableMarkdownBody({
    required this.data,
    required this.styleSheet,
    this.highlightQuery,
    this.softLineBreak = true,
    this.sizedImageBuilder,
    this.onTapLink,
    this.nrId,
    super.key,
  });

  static final _highlightSyntax = SearchHighlightSyntax();
  static final _highlightBuilders = <String, MarkdownElementBuilder>{
    'searchhl': SearchHighlightBuilder(),
  };

  @override
  Widget build(BuildContext context) {
    final processed = injectMarkdownHighlights(data, highlightQuery);

    return MarkdownBody(
      data: processed,
      selectable: true,
      softLineBreak: softLineBreak,
      styleSheet: styleSheet,
      inlineSyntaxes: [_highlightSyntax],
      builders: _highlightBuilders,
      onTapLink: onTapLink,
      sizedImageBuilder: sizedImageBuilder ??
          (nrId == null
              ? null
              : (config) => NrMarkdownImageBuilder(
                    uri: config.uri,
                    nrId: nrId!,
                    title: config.title,
                    alt: config.alt,
                  )),
    );
  }
}

class SearchHighlightSyntax extends md.InlineSyntax {
  SearchHighlightSyntax() : super(r'⟦([^⟧]+)⟧');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('searchhl', match.group(1)!));
    return true;
  }
}

class SearchHighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final baseStyle = preferredStyle ?? const TextStyle();
    return Text.rich(
      TextSpan(
        text: element.textContent,
        style: baseStyle.copyWith(
          backgroundColor: Colors.amber.withValues(alpha: 0.55),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
