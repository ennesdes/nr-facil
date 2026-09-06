import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/core/widgets/responsive_content.dart';
import 'package:nrfacil/core/widgets/update_count_badge.dart';
import 'package:nrfacil/core/widgets/update_highlight.dart';
import 'package:nrfacil/features/ads/widgets/persistent_banner_ad.dart';
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
    return Obx(() {
      final tab = controller.selectedTab.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(controller.tabTitle),
          centerTitle: false,
          actions: [
            _buildNotificationsBell(context),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Ajustes',
              onPressed: () => Get.to(() => const SettingsPage()),
            ),
          ],
        ),
        body: ResponsiveContent(
          child: IndexedStack(
            index: tab,
            children: [
              const SizedBox.expand(child: NormasTab()),
              const SizedBox.expand(child: FavoritosTab()),
              SizedBox.expand(
                child: SearchTab(isActive: tab == HomeController.tabBuscar),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PersistentBannerAd(),
            AppBottomNavBar(
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
          ],
        ),
      );
    });
  }

  Widget _buildNotificationsBell(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(() {
      final unreadCount = contentService.unreadUpdatesCount.value;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(
              unreadCount > 0
                  ? Icons.notifications
                  : Icons.notifications_outlined,
            ),
            color: unreadCount > 0
                ? UpdateHighlight.accentColor(context)
                : null,
            tooltip: unreadCount > 0
                ? '$unreadCount atualizações pendentes'
                : 'Atualizações',
            onPressed: () {
              Get.to(() => const UpdatesPage(), binding: UpdatesBinding());
            },
          ),
          Positioned(
            right: 4,
            top: 4,
            child: UpdateCountBadge(count: unreadCount),
          ),
        ],
      );
    });
  }
}
