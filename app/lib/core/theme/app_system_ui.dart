import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Estilo das barras de status e navegação do sistema, alinhado ao tema do app.
abstract final class AppSystemUi {
  /// Cor e ícones da barra de navegação do sistema para um fundo [surface].
  static SystemUiOverlayStyle overlayFor({
    required Brightness brightness,
    required Color surface,
  }) {
    final navIconBrightness =
        brightness == Brightness.dark ? Brightness.light : Brightness.dark;

    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: navIconBrightness,
      statusBarBrightness:
          brightness == Brightness.dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: surface,
      systemNavigationBarDividerColor: surface,
      systemNavigationBarIconBrightness: navIconBrightness,
      systemNavigationBarContrastEnforced: true,
    );
  }

  /// Estilo derivado do [Theme] atual, com fundo opcional (ex.: leitor).
  static SystemUiOverlayStyle forTheme(
    ThemeData theme, {
    Color? surface,
  }) {
    return overlayFor(
      brightness: theme.brightness,
      surface: surface ?? theme.colorScheme.surface,
    );
  }

  /// Aplica o estilo no Android (complementa [AnnotatedRegion]).
  static void apply(SystemUiOverlayStyle style) {
    if (kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(style);
  }
}

/// Propaga e aplica o estilo das barras do sistema conforme o tema.
class AppSystemUiScope extends StatefulWidget {
  final Widget child;
  final Color? surface;

  const AppSystemUiScope({
    required this.child,
    this.surface,
    super.key,
  });

  @override
  State<AppSystemUiScope> createState() => _AppSystemUiScopeState();
}

class _AppSystemUiScopeState extends State<AppSystemUiScope> {
  SystemUiOverlayStyle? _lastApplied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overlay = AppSystemUi.forTheme(theme, surface: widget.surface);

    if (_lastApplied != overlay) {
      _lastApplied = overlay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSystemUi.apply(overlay);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: widget.child,
    );
  }
}
