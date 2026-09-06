import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';

/// Estado vazio para quando não há NRs favoritadas.
class EmptyFavoritosState extends StatelessWidget {
  const EmptyFavoritosState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.star_outline,
      title: 'Sem favoritos ainda',
      body: 'Adicione normas aos favoritos para acessá-las rapidamente',
      actions: [
        FilledButton.icon(
          onPressed: () {
            Get.find<HomeController>().selectTab(HomeController.tabNormas);
          },
          icon: const Icon(Icons.library_books_outlined),
          label: const Text('Explorar normas'),
        ),
      ],
    );
  }
}
