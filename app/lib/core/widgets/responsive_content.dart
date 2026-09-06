import 'package:flutter/material.dart';
import 'package:nrfacil/core/utils/responsive_layout.dart';

/// Centraliza conteúdo e limita a largura em tablets, mantendo altura total.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContent({
    required this.child,
    this.maxWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedMax = maxWidth ?? ResponsiveLayout.listContentMaxWidth(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (screenWidth <= resolvedMax) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: resolvedMax),
        child: SizedBox(
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}
