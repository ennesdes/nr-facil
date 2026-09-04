import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/settings/views/settings_page.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nrfacil_settings_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await GetStorage.init();
    Get.put(ThemeController());
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    Get.reset();
  });

  testWidgets('SettingsPage exibe opções de tema e altera ThemeController',
      (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aparência'), findsOneWidget);
    expect(find.text('Política de privacidade'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    final controller = Get.find<ThemeController>();
    expect(controller.themeMode.value, ThemeMode.dark);
  });
}
