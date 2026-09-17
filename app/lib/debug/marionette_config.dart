import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

/// Marionette debug config — registry de widgets interativos customizados.
///
/// nr-facil usa widgets Material padrão, então este arquivo é uma base
/// para futuras extensões de DS customizadas se necessário.
MarionetteConfiguration get marionetteConfiguration {
  return MarionetteConfiguration(
    isInteractiveWidget: (type) => type == ListTile,
    extractText: (element) {
      final widget = element.widget;
      if (widget is ListTile) {
        final title = widget.title;
        if (title is Text) {
          return title.data ?? title.textSpan?.toPlainText();
        }
      }
      return null;
    },
  );
}
