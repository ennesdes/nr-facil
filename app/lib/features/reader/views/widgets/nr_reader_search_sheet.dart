import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Bottom sheet compacto de busca dentro da NR aberta.
class NrReaderSearchSheet extends StatefulWidget {
  final NRReaderController controller;

  const NrReaderSearchSheet({
    required this.controller,
    super.key,
  });

  static Future<void> show({
    required BuildContext context,
    required NRReaderController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        // viewInsets = teclado; padding.bottom = barra de navegação do sistema
        final bottomInset =
            mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: NrReaderSearchSheet(controller: controller),
        );
      },
    );
  }

  @override
  State<NrReaderSearchSheet> createState() => _NrReaderSearchSheetState();
}

class _NrReaderSearchSheetState extends State<NrReaderSearchSheet> {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
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
                    hintText: 'Buscar em toda a NR...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clear,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: widget.controller.searchInDocument,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => _buildNavigationRow(context)),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(BuildContext context) {
    final query = widget.controller.documentSearchQuery.value.trim();
    // Acesso explícito à lista reativa para o Obx detectar mudanças.
    final count = widget.controller.documentSearchResults.length;
    final isSearching = widget.controller.isDocumentSearching.value;

    if (query.isEmpty) {
      return Text(
        'Busque por seção, item ou palavra-chave',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }

    if (isSearching) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (count == 0) {
      return Text(
        'Nenhum resultado para "$query"',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      );
    }

    final current = widget.controller.currentHitIndex.value + 1;

    return Row(
      children: [
        Text(
          '$count resultado${count == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Anterior',
          onPressed: widget.controller.goToPreviousHit,
        ),
        Text(
          '$current / $count',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Próximo',
          onPressed: widget.controller.goToNextHit,
        ),
      ],
    );
  }
}
