import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/home/views/widgets/continuar_leitura_card.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';

/// Card "Continuar leitura" — exibir última NR aberta com progresso.
class ContinuarLeituraSection extends StatelessWidget {
  const ContinuarLeituraSection({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(() {
      final manifest = contentService.manifest.value;
      final lastOpenedNrId = contentService.lastOpenedNrId.value;
      // Observa mudanças de progresso/heading no histórico.
      contentService.readingHistoryVersion.value;
      if (lastOpenedNrId == null) return const SizedBox.shrink();

      final entry = manifest?.findNr(lastOpenedNrId);
      if (entry == null || entry.isRevoked) return const SizedBox.shrink();

      final positionLabel =
          contentService.getContinueReadingPositionLabel(lastOpenedNrId);
      final progress = contentService.getReadingProgressPercent(lastOpenedNrId);

      return ContinuarLeituraCard(
        nrEntry: entry,
        sectionLabel: positionLabel,
        progressPercent: progress,
        hasUpdate: contentService.hasUpdate(lastOpenedNrId),
        onTap: () {
          ReaderNavigation.open(nrId: lastOpenedNrId);
        },
      );
    });
  }
}
