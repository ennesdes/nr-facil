import 'package:flutter/material.dart';
import 'package:nrfacil/core/utils/responsive_layout.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';

/// Padding horizontal padrão dos blocos normativos no leitor.
class NrReaderBlockPadding extends StatelessWidget {
  final Widget child;

  const NrReaderBlockPadding({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.readerHorizontalPadding(
          context,
          base: kReaderHorizontalPadding,
        ),
      ),
      child: child,
    );
  }
}
