import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  testWidgets('shows HomePage with Favoritos and Todos tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verificar se os títulos das abas estão presentes
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);

    // HomeController dispara ContentService.sync() em background no onInit;
    // em ambiente de teste a request HTTP falha (mock retorna 400), o que
    // aciona um SnackBar de erro com timer próprio — drenar esse timer antes
    // do widget tree ser descartado, senão o teste falha com "Timer pending".
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
