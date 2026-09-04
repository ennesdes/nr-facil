import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';
import 'package:nrfacil/features/home/views/widgets/favoritos_tab.dart';
import 'package:nrfacil/features/home/views/widgets/todos_tab.dart';
import 'package:nrfacil/features/search/views/search_page.dart';
import 'package:nrfacil/features/settings/views/settings_page.dart';
import 'package:nrfacil/features/updates/bindings/updates_binding.dart';
import 'package:nrfacil/features/updates/views/updates_page.dart';

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
            _buildNotificationsBell(context),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Ajustes',
              onPressed: () => Get.to(() => const SettingsPage()),
            ),
          ],
          bottom: controller.contentService.isSyncing.value
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              : null,
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

  /// Construir ícone de notificações (sino) com badge reativo.
  ///
  /// O badge mostra a contagem de atualizações não lidas.
  /// Ao tocar, abre a tela de Atualizações.
  Widget _buildNotificationsBell(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(
      () {
        final unreadCount = contentService.unreadUpdatesCount.value;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Atualizações',
              onPressed: () {
                Get.to(
                  () => const UpdatesPage(),
                  binding: UpdatesBinding(),
                );
              },
            ),
            // Badge com contagem
            if (unreadCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.5,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onError,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
