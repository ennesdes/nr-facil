import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';
import 'package:nrfacil/features/home/views/widgets/favoritos_tab.dart';
import 'package:nrfacil/features/home/views/widgets/todos_tab.dart';
import 'package:nrfacil/features/search/views/search_page.dart';

/// HomePage — tela principal com bottom nav (Favoritos/Todos).
///
/// Estrutura:
/// - Bottom nav com 2 abas: Favoritos (0) e Todos (1)
/// - IndexedStack para alternar entre abas
/// - Lógica de seleção de aba padrão em HomeController
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: const Text('NR Fácil'),
          centerTitle: false,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar',
              onPressed: () {
                Get.to(() => const SearchPage());
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: controller.selectedTab.value,
          children: const [
            FavoritosTab(),
            TodosTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.selectedTab.value,
          onTap: controller.selectTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Todos',
            ),
          ],
        ),
      ),
    );
  }
}
