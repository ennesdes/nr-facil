import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/view_padding.dart';

/// Espaço extra no fim de [SingleChildScrollView] para CTAs não colarem na
/// barra de navegação nativa (edge-to-edge) e manter respiro visual.
class AppScrollBottomInset extends StatelessWidget {
  const AppScrollBottomInset({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ViewPadding.bottomOf(context) + AppSpacing.lg,
    );
  }
}
