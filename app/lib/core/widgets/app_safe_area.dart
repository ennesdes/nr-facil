import 'package:flutter/material.dart';

/// Corpo de [Scaffold] para telas sem barra inferior do app (leitor, ajustes, etc.).
///
/// Respeita a barra de navegação nativa sem afetar o topo (já coberto pelo AppBar).
class AppScaffoldBody extends StatelessWidget {
  final Widget child;

  const AppScaffoldBody({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      maintainBottomViewPadding: true,
      child: child,
    );
  }
}

/// Envolve a barra de navegação inferior do app para ficar acima da barra do sistema.
class AppBottomNavBar extends StatelessWidget {
  final Widget child;

  const AppBottomNavBar({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        maintainBottomViewPadding: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Conteúdo de bottom sheet com inset inferior garantido.
class AppBottomSheetBody extends StatelessWidget {
  final Widget child;
  final bool respondToKeyboard;

  const AppBottomSheetBody({
    required this.child,
    this.respondToKeyboard = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemBottom = mediaQuery.viewPadding.bottom;
    final keyboardBottom = mediaQuery.viewInsets.bottom;
    final bottom = respondToKeyboard
        ? (keyboardBottom > systemBottom ? keyboardBottom : systemBottom)
        : systemBottom;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: child,
      ),
    );
  }
}
