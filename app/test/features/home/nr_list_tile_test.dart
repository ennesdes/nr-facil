import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';

ManifestEntry _entry({bool revogada = false}) {
  return ManifestEntry(
    id: 'nr-02',
    title: 'INSPEÇÃO PRÉVIA',
    version: '1.0.0',
    hash: 'abc',
    pdfHash: 'def',
    updatedAt: DateTime(2024, 1, 1),
    url: 'https://example.com/nr-02.md',
    revogada: revogada,
  );
}

void main() {
  testWidgets('NrListTile revogada não exibe badge Atualizada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrListTile(
            nrEntry: _entry(revogada: true),
            isFavorite: false,
            hasUpdate: true,
            isRevoked: true,
            onTap: () {},
            onToggleFavorite: () {},
          ),
        ),
      ),
    );

    expect(find.text('Atualização disponível'), findsNothing);
    expect(find.text('Revogada'), findsOneWidget);
    expect(find.text('Inspeção prévia'), findsOneWidget);
  });

  testWidgets('NrListTile ativa exibe badge quando há update',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrListTile(
            nrEntry: _entry(),
            isFavorite: false,
            hasUpdate: true,
            isRevoked: false,
            onTap: () {},
            onToggleFavorite: () {},
          ),
        ),
      ),
    );

    expect(find.text('Atualização disponível'), findsOneWidget);
    expect(find.text('Revogada'), findsNothing);
  });

  testWidgets('NrListTile mantém título próximo ao label com ações visíveis',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrListTile(
            nrEntry: _entry(),
            isFavorite: false,
            hasUpdate: false,
            isRevoked: false,
            onTap: () {},
            onToggleFavorite: () {},
          ),
        ),
      ),
    );

    final labelTop = tester.getTopLeft(find.text('NR-02')).dy;
    final labelBottom =
        labelTop + tester.getSize(find.text('NR-02')).height;
    final titleTop = tester.getTopLeft(find.text('Inspeção prévia')).dy;

    expect(titleTop - labelBottom, lessThan(24));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });
}
