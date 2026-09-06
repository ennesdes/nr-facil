import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';

/// Link de texto padronizado do design system.
///
/// Para ações terciárias inline: "Buscar no conteúdo", "Ver PDF oficial", etc.
class AppTextLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool useInfoColor;
  final int? maxLines;

  const AppTextLink({
    required this.label,
    this.onPressed,
    this.icon,
    this.useInfoColor = false,
    this.maxLines,
    super.key,
  });

  static ButtonStyle get _buttonStyle => TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = useInfoColor
        ? context.semanticColors.info
        : colorScheme.primary;
    final labelStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: color);
    final textOverflow = maxLines != null ? TextOverflow.ellipsis : null;

    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: labelStyle,
          maxLines: maxLines,
          overflow: textOverflow,
        ),
        style: _buttonStyle,
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: _buttonStyle,
      child: Text(
        label,
        style: labelStyle,
        maxLines: maxLines,
        overflow: textOverflow,
      ),
    );
  }
}
