import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';

/// Chip de filtro/ação padronizado do design system.
///
/// Mesmo visual dos filtros da aba Normas (Todas, Favoritas, Atualizadas).
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? trailing;
  final bool enabled;
  final bool emphasized;

  const AppFilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.trailing,
    this.enabled = true,
    this.emphasized = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = selected || emphasized;
    final foreground =
        isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
      selected: isActive,
      showCheckmark: false,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(color: foreground),
      onSelected: enabled && onTap != null ? (_) => onTap!() : null,
    );
  }
}

/// Linha horizontal com chips de filtro/ação (scroll quando necessário).
class AppFilterChipRow extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppFilterChipRow({
    required this.children,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(children: children),
    );
  }
}
