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

import 'core/bindings/app_binding.dart';
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

/// Hash alternativo servido na 2ª+ fetch de manifest.json — simula NR atualizada.
const _e2eUpdatedNrHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

/// Resposta UTF-8 — `http.Response(String)` corrompe bytes não-ASCII em bodyBytes.
http.Response _utf8Response(String body, int statusCode) {
  return http.Response.bytes(utf8.encode(body), statusCode);
}

/// Mock HTTP client para E2E — serve conteúdo de fixture local (nr-25).
///
/// Responde a requisições do ContentService sem conexão de rede real.
/// Simula um manifest com apenas nr-25 disponível.
/// Na 2ª sincronização, retorna hash diferente para exercitar fluxo de atualizações.
http.Client _createE2eMockHttpClient() {
  var manifestFetchCount = 0;

  return MockClient((request) async {
    final path = request.url.path;

    // Servir manifest.json do asset e2e_seed
    if (path.endsWith('/manifest.json')) {
      try {
        manifestFetchCount++;
        final content = await rootBundle.loadString(
          'assets/e2e_seed/manifest.json',
        );

        if (manifestFetchCount > 1) {
          final json = jsonDecode(content) as Map<String, dynamic>;
          final nrs = json['nrs'] as List<dynamic>;
          for (final nr in nrs) {
            if (nr is Map<String, dynamic>) {
              nr['hash'] = _e2eUpdatedNrHash;
            }
          }
          return _utf8Response(jsonEncode(json), 200);
        }

        return _utf8Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar manifest.json do asset: $e');
        return _utf8Response('manifest not found', 404);
      }
    }

    // Servir nr-25.md do asset e2e_seed
    if (path.endsWith('/nr-25.md')) {
      try {
        final content = await rootBundle.loadString(
          'assets/e2e_seed/nr-25/nr-25.md',
        );
        return _utf8Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar nr-25.md do asset: $e');
        return _utf8Response('nr-25.md not found', 404);
      }
    }

    // Servir index.json de nr-25
    if (path.endsWith('/nr-25/index.json') || path.endsWith('/index.json')) {
      try {
        final content = await rootBundle.loadString(
          'assets/e2e_seed/nr-25/index.json',
        );
        return _utf8Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar index.json do asset: $e');
        return _utf8Response('index.json not found', 404);
      }
    }

    // Servir app_meta.json do asset e2e_seed (feed de atualizações para nr-25)
    if (path.endsWith('/app_meta.json')) {
      try {
        final content = await rootBundle.loadString(
          'assets/e2e_seed/app_meta.json',
        );
        return _utf8Response(content, 200);
      } catch (e) {
        AppLogger.warning('Falha ao carregar app_meta.json do asset: $e');
        return _utf8Response('app_meta not found', 404);
      }
    }

    // Qualquer outra URL retorna 404 — determináticos, sem rede real
    AppLogger.debug('E2E mock: 404 para $path');
    return _utf8Response('e2e mock: endpoint not found', 404);
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
        initialBinding: AppBinding(
          contentServiceBuilder: () =>
              ContentService(httpClient: _createE2eMockHttpClient()),
        ),
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
