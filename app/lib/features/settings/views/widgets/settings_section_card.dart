import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';

/// Bloco agrupado de ajustes — card flat com borda conforme design system.
class SettingsSectionCard extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;

  const SettingsSectionCard({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            if (children.isNotEmpty) ...[
              SizedBox(height: description != null ? AppSpacing.md : AppSpacing.sm),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}
