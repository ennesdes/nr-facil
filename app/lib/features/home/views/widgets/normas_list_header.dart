import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';
import 'package:nrfacil/features/home/controllers/normas_controller.dart';
/// Cabeçalho da aba Normas: busca local e filtros.
class NormasListHeader extends StatefulWidget {
  const NormasListHeader({super.key});

  @override
  State<NormasListHeader> createState() => _NormasListHeaderState();
}

class _NormasListHeaderState extends State<NormasListHeader> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  NormasController get _normasController => Get.find<NormasController>();
  HomeController get _homeController => Get.find<HomeController>();
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _normasController.query.value);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _normasController.setQuery(_searchController.text);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _normasController.clearQuery();
  }

  void _openContentSearch() {
    final q = _normasController.query.value;
    if (q.isEmpty) return;
    _homeController.openSearchTab(q);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final query = _normasController.query.value;
      final activeFilter = _normasController.filter.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por número, nome ou assunto',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (query.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextButton(
                  onPressed: _openContentSearch,
                  child: Text('Buscar "$query" no conteúdo das normas →'),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                for (final item in _filterItems)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(item.label),
                      selected: activeFilter == item.filter,
                      showCheckmark: false,
                      selectedColor: colorScheme.primary,
                      labelStyle: TextStyle(
                        color: activeFilter == item.filter
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (_) =>
                          _normasController.setFilter(item.filter),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  static const _filterItems = [
    _FilterItem(NormasFilter.all, 'Todas'),
    _FilterItem(NormasFilter.favorites, 'Favoritas'),
    _FilterItem(NormasFilter.updated, 'Atualizadas'),
    _FilterItem(NormasFilter.revoked, 'Revogadas'),
  ];
}

class _FilterItem {
  const _FilterItem(this.filter, this.label);

  final NormasFilter filter;
  final String label;
}
