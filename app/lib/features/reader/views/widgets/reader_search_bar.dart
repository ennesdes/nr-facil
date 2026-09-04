import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_shimmer.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Barra de busca inline abaixo da AppBar do leitor.
class ReaderSearchBar extends StatefulWidget {
  final NRReaderController controller;
  final VoidCallback? onClose;

  const ReaderSearchBar({
    required this.controller,
    this.onClose,
    super.key,
  });

  @override
  State<ReaderSearchBar> createState() => _ReaderSearchBarState();
}

class _ReaderSearchBarState extends State<ReaderSearchBar> {
  final _queryController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final existing = widget.controller.documentSearchQuery.value;
    if (existing.isNotEmpty) {
      _queryController.text = existing;
    }
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      widget.controller.searchInDocument(_queryController.text);
    });
  }

  void _clear() {
    _queryController.clear();
    widget.controller.clearDocumentSearch();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _queryController.text.trim();
    final showNav = query.isNotEmpty;

    return Material(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar nesta NR...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _queryController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: _clear,
                              )
                            : null,
                        filled: true,
                        fillColor: colorScheme.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: widget.controller.searchInDocument,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar busca',
                    onPressed: widget.onClose ?? widget.controller.closeSearch,
                  ),
                ],
              ),
              if (showNav) ...[
                const SizedBox(height: AppSpacing.xs),
                Obx(() => _buildNavigationRow(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationRow(BuildContext context) {
    final query = widget.controller.documentSearchQuery.value.trim();
    final count = widget.controller.documentSearchResults.length;
    final isSearching = widget.controller.isDocumentSearching.value;
    final colorScheme = Theme.of(context).colorScheme;

    if (isSearching) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: AppShimmerIcon(size: 18),
      );
    }

    if (count == 0) {
      return Text(
        'Nenhum resultado para "$query"',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      );
    }

    final current = widget.controller.currentHitIndex.value + 1;

    return Row(
      children: [
        Text(
          '$current de $count',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const Spacer(),
        IconButton(
          onPressed: widget.controller.goToPreviousHit,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Anterior',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          onPressed: widget.controller.goToNextHit,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Próximo',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
