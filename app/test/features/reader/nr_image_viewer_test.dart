import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_image_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NrImageViewer', () {
    late Directory tempDir;
    late File imageFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nr_image_viewer_');
      imageFile = File('${tempDir.path}/test.png');
      await imageFile.writeAsBytes([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('abre com zoom, salvar e compartilhar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      NrImageViewer.open(
                        context: context,
                        imageProvider: FileImage(imageFile),
                        localFilePath: imageFile.path,
                        fileName: 'NR-06-imagem.png',
                        caption: 'Diagrama',
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byTooltip('Salvar imagem'), findsOneWidget);
      expect(find.byTooltip('Compartilhar'), findsOneWidget);

      final scaleBefore = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getMaxScaleOnAxis();

      final center = tester.getCenter(find.byType(Image));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();

      final scaleAfter = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .getMaxScaleOnAxis();

      expect(scaleBefore, closeTo(1.0, 0.05));
      expect(scaleAfter, closeTo(2.5, 0.05));

      final matrix = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value;
      expect(matrix.storage[12], isNot(closeTo(0.0, 1.0)));
      expect(matrix.storage[13], isNot(closeTo(0.0, 1.0)));
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
