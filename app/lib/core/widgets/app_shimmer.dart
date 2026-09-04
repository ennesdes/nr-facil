import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';

/// Efeito shimmer reutilizável — padrão de carregamento do app.
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.surfaceContainerHighest;
    final highlight = Color.lerp(base, colorScheme.surface, 0.45)!;

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final slide = -1.0 + _controller.value * 2;
              return LinearGradient(
                begin: Alignment(slide - 1, 0),
                end: Alignment(slide + 1, 0),
                colors: [base, highlight, base],
                stops: const [0.2, 0.5, 0.8],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Retângulo arredondado com shimmer — bloco básico dos placeholders.
class AppShimmerBox extends StatelessWidget {
  const AppShimmerBox({
    this.width,
    this.height,
    this.borderRadius = AppRadius.sm,
    super.key,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppShimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer circular compacto — ícones e ações inline.
class AppShimmerIcon extends StatelessWidget {
  const AppShimmerIcon({
    this.size = 20,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return AppShimmerBox(
      width: size,
      height: size,
      borderRadius: AppRadius.full,
    );
  }
}
