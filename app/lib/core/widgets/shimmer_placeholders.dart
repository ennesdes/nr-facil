import 'package:flutter/material.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_shimmer.dart';

/// Placeholder de um tile de NR na lista.
class NrListTileShimmer extends StatelessWidget {
  const NrListTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppShimmerBox(width: 56, height: 16),
                const SizedBox(height: 2),
                const AppShimmerBox(width: double.infinity, height: 14),
                const SizedBox(height: AppSpacing.xs),
                const AppShimmerBox(width: 220, height: 14),
              ],
            ),
          ),
          const AppShimmerIcon(size: 24),
          const AppShimmerIcon(size: 24),
        ],
      ),
    );
  }
}

/// Lista de tiles shimmer para abas de normas/favoritos.
class NrListShimmer extends StatelessWidget {
  const NrListShimmer({
    this.itemCount = 8,
    this.showContinueCard = false,
    super.key,
  });

  final int itemCount;
  final bool showContinueCard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (showContinueCard) const ContinuarLeituraCardShimmer(),
        for (var i = 0; i < itemCount; i++) const NrListTileShimmer(),
      ],
    );
  }
}

/// Placeholder do card "Continuar leitura".
class ContinuarLeituraCardShimmer extends StatelessWidget {
  const ContinuarLeituraCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppShimmerBox(width: 120, height: 12),
            const SizedBox(height: AppSpacing.sm),
            const AppShimmerBox(width: double.infinity, height: 18),
            const SizedBox(height: AppSpacing.xs),
            const AppShimmerBox(width: 160, height: 14),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: AppShimmerBox(height: 4, borderRadius: 2)),
                const SizedBox(width: AppSpacing.sm),
                const AppShimmerBox(width: 32, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer da aba Normas — cabeçalho + lista.
class NormasTabShimmer extends StatelessWidget {
  const NormasTabShimmer({super.key});

  static const _itemCount = 8;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _NormasHeaderShimmer()),
        const SliverToBoxAdapter(child: ContinuarLeituraCardShimmer()),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const NrListTileShimmer(),
            childCount: _itemCount,
          ),
        ),
      ],
    );
  }
}

class _NormasHeaderShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppShimmerBox(height: 48, borderRadius: AppRadius.sm),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                AppShimmerBox(
                  width: i == 0 ? 64 : 88,
                  height: 32,
                  borderRadius: AppRadius.full,
                ),
                if (i < 3) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Shimmer do corpo do leitor normativo.
class ReaderBodyShimmer extends StatelessWidget {
  const ReaderBodyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const AppShimmerBox(width: 180, height: 24),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 6; i++) ...[
          const AppShimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: AppSpacing.sm),
          AppShimmerBox(
            width: i.isEven ? double.infinity : 280,
            height: 14,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

/// Shimmer dos resultados de busca.
class SearchResultsShimmer extends StatelessWidget {
  const SearchResultsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: const [
        _SearchResultTileShimmer(),
        _SearchResultTileShimmer(),
        _SearchResultTileShimmer(),
        _SearchResultTileShimmer(),
        _SearchResultTileShimmer(),
      ],
    );
  }
}

class _SearchResultTileShimmer extends StatelessWidget {
  const _SearchResultTileShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppShimmerBox(width: 72, height: 14),
          const SizedBox(height: AppSpacing.xs),
          const AppShimmerBox(width: double.infinity, height: 16),
          const SizedBox(height: AppSpacing.xs),
          const AppShimmerBox(width: double.infinity, height: 12),
          const SizedBox(height: AppSpacing.xs),
          const AppShimmerBox(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// Placeholder retangular para imagens em carregamento.
class ImageShimmerPlaceholder extends StatelessWidget {
  const ImageShimmerPlaceholder({
    this.height = 200,
    super.key,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return AppShimmerBox(
      width: double.infinity,
      height: height,
      borderRadius: AppRadius.md,
    );
  }
}
