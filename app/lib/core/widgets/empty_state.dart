import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Estado vazio padronizado do design system.
///
/// Ícone 64dp, título, corpo opcional e ações opcionais (botões/chips).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final List<Widget>? actions;

  const EmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.actions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
