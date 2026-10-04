import 'package:nrfacil/core/models/acknowledge_update_reason.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/services/analytics_service.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';

/// Navega ao trecho alterado e registra revisão do diff.
void openUpdateItemInReader({
  required ContentService contentService,
  required String nrId,
  required UpdateItem item,
  NRReaderController? readerController,
}) {
  contentService.acknowledgeNrUpdate(
    nrId,
    reason: AcknowledgeUpdateReason.itemTap,
  );

  if (readerController != null && readerController.nrId == nrId) {
    readerController.navigateToItemNumber(item.item);
    return;
  }

  ReaderNavigation.open(
    nrId: nrId,
    source: AnalyticsService.sourceAtualizacoes,
    initialAnchor: item.item,
  );
}
