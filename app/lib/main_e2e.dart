import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'core/constants/app_config.dart';
import 'core/services/content_service.dart';
import 'core/utils/app_logger.dart';
import 'core/controllers/theme_controller.dart';
import 'core/theme/app_system_ui.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/view_padding.dart';
import 'debug/marionette_config.dart';
import 'debug/marionette_extensions.dart';
import 'features/home/views/home_page.dart';

/// Mock HTTP client para E2E — serve conteúdo de fixture local (nr-25).
///
/// Responde a requisições do ContentService sem conexão de rede real.
/// Simula um manifest com apenas nr-25 disponível.
http.Client _createE2eMockHttpClient() {
  return MockClient((request) async {
    final path = request.url.path;

    // Servir manifest.json do asset e2e_seed
    if (path.endsWith('/manifest.json')) {
      try {
        final content = await rootBundle.loadString('assets/e2e_seed/manifest.json');
        return http.Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar manifest.json do asset: $e');
        return http.Response('manifest not found', 404);
      }
    }

    // Servir nr-25.md do asset e2e_seed
    if (path.endsWith('/nr-25.md')) {
      try {
        final content = await rootBundle.loadString('assets/e2e_seed/nr-25/nr-25.md');
        return http.Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar nr-25.md do asset: $e');
        return http.Response('nr-25.md not found', 404);
      }
    }

    // Servir index.json de nr-25
    if (path.endsWith('/nr-25/index.json') || path.endsWith('/index.json')) {
      try {
        final content = await rootBundle.loadString('assets/e2e_seed/nr-25/index.json');
        return http.Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar index.json do asset: $e');
        return http.Response('index.json not found', 404);
      }
    }

    // Servir app_meta.json vazio (fixture não tem atualizações)
    if (path.endsWith('/app_meta.json')) {
      return http.Response(
        jsonEncode({
          'generated_at': '2026-09-17T00:00:00.000Z',
          'min_app_version': '0.0.1',
          'updates': <Map<String, dynamic>>[],
        }),
        200,
      );
    }

    // Qualquer outra URL retorna 404 — determináticos, sem rede real
    AppLogger.debug('E2E mock: 404 para $path');
    return http.Response('e2e mock: endpoint not found', 404);
  });
}

Future<void> main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized(marionetteConfiguration);
    registerMarionetteDebugExtensions();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Firebase omitido neste entrypoint de teste — não é essencial
    // para validar o ContentService com mock.
    // Se for necessário (ex.: analytics), descomente:
    //
    // try {
    //   await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform,
    //   );
    //   // await configureCrashReporting();
    //   // await configurePerformanceMonitoring();
    // } catch (e, st) {
    //   AppLogger.error('Falha ao inicializar Firebase (E2E)', e, st);
    // }
  }

  await GetStorage.init();

  Get.put(ThemeController(), permanent: true);

  if (AppConfig.adsEnabled && !kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e, st) {
      AppLogger.error('Falha ao inicializar AdMob (E2E)', e, st);
    }
  }

  runApp(MyAppE2E());
}

/// Binding customizado que injeta o mock HTTP client no ContentService.
class E2EBinding extends Bindings {
  @override
  void dependencies() {
    final mockHttpClient = _createE2eMockHttpClient();
    Get.put<http.Client>(mockHttpClient, permanent: true);

    // ContentService com client mockado
    Get.put(
      ContentService(
        httpClient: mockHttpClient,
      ),
      permanent: true,
    );

    // Resto do bootstrap (sem replicar AppBinding inteiro, só o essencial)
  }
}

class MyAppE2E extends GetView<ThemeController> {
  const MyAppE2E({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: true, // Deixar visível para E2E identificar
        title: 'NR Fácil (E2E)',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode.value,
        initialBinding: E2EBinding(),
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
