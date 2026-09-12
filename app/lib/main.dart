import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/bindings/app_binding.dart';
import 'core/constants/app_config.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/crash_reporting.dart';
import 'core/utils/performance_monitoring.dart';
import 'core/controllers/theme_controller.dart';
import 'core/theme/app_system_ui.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/view_padding.dart';
import 'features/home/views/home_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await configureCrashReporting();
      await configurePerformanceMonitoring();
    } catch (e, st) {
      // Falha no Firebase não deve impedir o app de abrir.
      AppLogger.error('Falha ao inicializar Firebase', e, st);
    }
  }

  await GetStorage.init();

  Get.put(ThemeController(), permanent: true);

  if (AppConfig.adsEnabled && !kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e, st) {
      // Falha no AdMob não deve impedir o app de abrir (revisão Play Store).
      AppLogger.error('Falha ao inicializar AdMob', e, st);
    }
  }

  runApp(const MyApp());
}

class MyApp extends GetView<ThemeController> {
  const MyApp({super.key, this.initialBinding});

  final Bindings? initialBinding;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'NR Fácil',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode.value,
        initialBinding: initialBinding ?? AppBinding(),
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return AppSystemUiScope(
            child: MediaQuery(
              data: ViewPadding.ensureSystemPadding(mediaQuery),
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const HomePage(),
      ),
    );
  }
}
