import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/nr_index.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

/// Drawer de navegação com seções, subitens e campo "Ir para item".
class ReaderDrawer extends StatefulWidget {
  final NrStructure? structure;
  final NrIndex? legacyIndex;
  final String? currentSectionId;
  final String? currentItemNumber;
  final String? currentPositionLabel;
  final int? progressPercent;
  final void Function(String target) onNavigate;
  final void Function(String itemNumber) onNavigateToItem;

  const ReaderDrawer({
    required this.structure,
    required this.legacyIndex,
    required this.onNavigate,
    required this.onNavigateToItem,
    this.currentSectionId,
    this.currentItemNumber,
    this.currentPositionLabel,
    this.progressPercent,
    super.key,
  });

  @override
  State<ReaderDrawer> createState() => _ReaderDrawerState();
}

class _ReaderDrawerState extends State<ReaderDrawer> {
  final _itemController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentItemKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToCurrent();
  }

  @override
  void didUpdateWidget(ReaderDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentItemNumber != widget.currentItemNumber ||
        oldWidget.currentSectionId != widget.currentSectionId) {
      _scheduleScrollToCurrent();
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _currentItemKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.3,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final structure = widget.structure;
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      width: MediaQuery.sizeOf(context).width * 0.88,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              positionLabel: widget.currentPositionLabel,
              progressPercent: widget.progressPercent,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _JumpToItemField(
                controller: _itemController,
                onSubmit: _submitItem,
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
            Expanded(
              child: structure != null && structure.sections.isNotEmpty
                  ? _buildStructureList(structure)
                  : _buildLegacyIndex(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateAfterClose(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      action();
    });
  }

  void _submitItem(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _navigateAfterClose(() => widget.onNavigateToItem(trimmed));
  }

  bool _isSectionActive(String sectionId) =>
      widget.currentSectionId == sectionId;

  bool _isSectionSelected(String sectionId) =>
      widget.currentSectionId == sectionId &&
      widget.currentItemNumber == null;

  bool _isItemSelected(String itemNumber) =>
      widget.currentItemNumber?.trim() == itemNumber.trim();

  bool _sectionContainsCurrentItem(NrSection section) {
    if (widget.currentItemNumber == null) return false;
    final current = widget.currentItemNumber!.trim();
    return section.blocks.whereType<NrItemBlock>().any(
          (b) => b.number.trim() == current,
        );
  }

  Widget _buildStructureList(NrStructure structure) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      children: [
        if (structure.preamble.blocks.isNotEmpty)
          _IndexNavTile(
            label: 'Publicação e alterações',
            icon: Icons.history_edu_outlined,
            isSelected: widget.currentSectionId == 'preamble',
            onTap: () => _navigateAfterClose(() => widget.onNavigate('preamble')),
          ),
        ...structure.sections.map((section) {
          final sectionLabel = formatSectionTitle(
            section.number,
            section.title,
          );
          final items = section.blocks
              .whereType<NrItemBlock>()
              .where((b) => b.number.isNotEmpty)
              .toList();
          final sectionActive = _isSectionActive(section.id);
          final containsCurrent = _sectionContainsCurrentItem(section);

          if (items.isEmpty) {
            return _IndexNavTile(
              label: sectionLabel,
              isSelected: _isSectionSelected(section.id),
              isActive: sectionActive,
              onTap: () => _navigateAfterClose(() => widget.onNavigate(section.id)),
            );
          }

          return _IndexSectionGroup(
            sectionLabel: sectionLabel,
            isSectionSelected: _isSectionSelected(section.id),
            isActive: sectionActive || containsCurrent,
            initiallyExpanded: sectionActive || containsCurrent,
            children: items.map((item) {
              final selected = _isItemSelected(item.number);
              final tile = _IndexItemTile(
                number: item.number,
                snippet: stripInlineMarkup(item.text),
                isSelected: selected,
                onTap: () =>
                    _navigateAfterClose(() => widget.onNavigateToItem(item.number)),
              );
              if (selected) {
                return KeyedSubtree(key: _currentItemKey, child: tile);
              }
              return tile;
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildLegacyIndex() {
    final headings = widget.legacyIndex?.headings ?? [];
    if (headings.isEmpty) {
      return const EmptyState(
        icon: Icons.list_alt,
        title: 'Índice indisponível',
        body: 'O índice desta NR não pôde ser carregado.',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      itemCount: headings.length,
      itemBuilder: (context, index) {
        final heading = headings[index];
        return _IndexNavTile(
          label: heading.text,
          onTap: () => _navigateAfterClose(() => widget.onNavigate(heading.text)),
        );
      },
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String? positionLabel;
  final int? progressPercent;

  const _DrawerHeader({
    required this.positionLabel,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = positionLabel?.trim();
    final percent = (progressPercent ?? 0).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Índice',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (label != null && label.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Você está em',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              minHeight: 4,
                              backgroundColor: colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.15),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$percent%',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JumpToItemField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  const _JumpToItemField({
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Ir para item (ex.: 6.5.1)',
        prefixIcon: const Icon(Icons.tag, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'Ir',
          onPressed: () => onSubmit(controller.text),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textInputAction: TextInputAction.go,
      onSubmitted: onSubmit,
    );
  }
}

class _IndexSectionGroup extends StatelessWidget {
  final String sectionLabel;
  final bool isSectionSelected;
  final bool isActive;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _IndexSectionGroup({
    required this.sectionLabel,
    required this.isSectionSelected,
    required this.isActive,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey('section-$sectionLabel-$initiallyExpanded'),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        collapsedIconColor:
            isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        leading: isActive
            ? Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : const SizedBox(width: 4),
        title: Text(
          sectionLabel,
          style: textTheme.titleSmall?.copyWith(
            fontWeight:
                isSectionSelected || isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
        children: children,
      ),
    );
  }
}

class _IndexNavTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final bool isActive;
  final VoidCallback onTap;

  const _IndexNavTile({
    required this.label,
    required this.onTap,
    this.icon,
    this.isSelected = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlighted = isSelected || isActive;

    return _IndexTileShell(
      isSelected: highlighted,
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: highlighted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
                    color: highlighted
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexItemTile extends StatelessWidget {
  final String number;
  final String snippet;
  final bool isSelected;
  final VoidCallback onTap;

  const _IndexItemTile({
    required this.number,
    required this.snippet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _IndexTileShell(
      isSelected: isSelected,
      onTap: onTap,
      indent: AppSpacing.lg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              snippet,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs, top: 2),
              child: Icon(
                Icons.my_location,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _IndexTileShell extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;
  final double indent;

  const _IndexTileShell({
    required this.child,
    required this.isSelected,
    required this.onTap,
    this.indent = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: indent,
        right: AppSpacing.sm,
        top: 2,
        bottom: 2,
      ),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border(
                      left: BorderSide(
                        color: colorScheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm + 2,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
