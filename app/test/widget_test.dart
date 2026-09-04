import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:nrfacil/core/controllers/theme_controller.dart';
import 'package:nrfacil/main.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nrfacil_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    await GetStorage.init();
    Get.put(ThemeController(), permanent: true);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
    Get.reset();
  });

  testWidgets('shows HomePage with Normas, Favoritos and Buscar tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const TickerMode(
        enabled: false,
        child: MyApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Normas'), findsAtLeast(1));
    expect(find.text('Favoritos'), findsAtLeast(1));
    expect(find.text('Buscar'), findsAtLeast(1));
  });
}
