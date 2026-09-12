import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_shimmer.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';

/// Estado de carregamento/baixando NR — leitor e overlays de lista.
class NrDownloadLoadingView extends StatelessWidget {
  const NrDownloadLoadingView({
    required this.title,
    this.subtitle,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final header = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDownloadIcon(color: colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: header,
        ),
        const Expanded(child: ReaderBodyShimmer(showHeader: false)),
      ],
    );
  }
}

class _PulsingDownloadIcon extends StatefulWidget {
  const _PulsingDownloadIcon({required this.color});

  final Color color;

  @override
  State<_PulsingDownloadIcon> createState() => _PulsingDownloadIconState();
}

class _PulsingDownloadIconState extends State<_PulsingDownloadIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AppShimmer(
        child: Icon(
          Icons.cloud_download_outlined,
          size: 44,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Overlay semitransparente sobre o tile da lista durante download.
class NrListTileDownloadOverlay extends StatelessWidget {
  const NrListTileDownloadOverlay({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.78),
        ),
        child: NrDownloadLoadingView(title: 'Baixando $label…', compact: true),
      ),
    );
  }
}
