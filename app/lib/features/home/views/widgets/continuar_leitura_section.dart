import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/home/views/widgets/continuar_leitura_card.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';

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

      final heading = contentService.getLastHeadingViewed(lastOpenedNrId);
      final progress = contentService.getReadingProgressPercent(lastOpenedNrId);

      return ContinuarLeituraCard(
        nrEntry: entry,
        sectionLabel: heading,
        progressPercent: progress,
        onTap: () {
          Get.to(
            () => NRReaderPage(nrId: lastOpenedNrId),
            binding: ReaderBinding(nrId: lastOpenedNrId),
          );
        },
      );
    });
  }
}
