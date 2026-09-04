import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';
import 'package:nrfacil/features/home/views/widgets/favoritos_tab.dart';
import 'package:nrfacil/features/home/views/widgets/normas_tab.dart';
import 'package:nrfacil/features/search/views/search_tab.dart';
import 'package:nrfacil/features/settings/views/settings_page.dart';
import 'package:nrfacil/features/updates/bindings/updates_binding.dart';
import 'package:nrfacil/features/updates/views/updates_page.dart';

/// HomePage — shell principal com bottom nav (Normas / Favoritos / Buscar).
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final tab = controller.selectedTab.value;

        return Scaffold(
          appBar: AppBar(
            title: Text(controller.tabTitle),
            centerTitle: false,
            elevation: 1,
            actions: [
              _buildNotificationsBell(context),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Ajustes',
                onPressed: () => Get.to(() => const SettingsPage()),
              ),
            ],
          ),
          body: IndexedStack(
            index: tab,
            children: [
              const SizedBox.expand(child: NormasTab()),
              const SizedBox.expand(child: FavoritosTab()),
              SizedBox.expand(
                child: SearchTab(
                  isActive: tab == HomeController.tabBuscar,
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            child: BottomNavigationBar(
              currentIndex: tab,
              onTap: controller.selectTab,
              items: [
              BottomNavigationBarItem(
                icon: Icon(
                  tab == HomeController.tabNormas
                      ? Icons.library_books
                      : Icons.library_books_outlined,
                ),
                label: 'Normas',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  tab == HomeController.tabFavoritos
                      ? Icons.star
                      : Icons.star_border,
                ),
                label: 'Favoritos',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  tab == HomeController.tabBuscar
                      ? Icons.search
                      : Icons.search_outlined,
                ),
                label: 'Buscar',
              ),
              ],
            ),
          ),
        );
      },
    );
  }

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
