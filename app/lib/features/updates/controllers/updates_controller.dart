import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';

/// Controller para a tela de Atualizações.
///
/// Responsabilidades:
/// - Expor lista reativa de NRs com atualizações pendentes
/// - Marcar NR como vista ao abrir leitor
/// - Navegar para o leitor da NR
class UpdatesController extends GetxController {
  final ContentService _contentService;

  UpdatesController({required this._contentService});

  /// Obter lista reativa de NRs com atualizações.
  ///
  /// Usa computed() para manter sincronizado com manifest e hash storage.
  late final updatedNrs = Rx<List<ManifestEntry>>(_contentService.updatedNrs);

  @override
  void onInit() {
    super.onInit();

    // Observar mudanças no manifest ou unread count para atualizar a lista
    ever(_contentService.manifest, (_) {
      updatedNrs.value = _contentService.updatedNrs;
    });

    ever(_contentService.unreadUpdatesCount, (_) {
      updatedNrs.value = _contentService.updatedNrs;
    });
  }

  /// Abrir leitor de uma NR e marcar como vista.
  void openNrAndMarkSeen(ManifestEntry entry) {
    _contentService.markNrAsSeen(entry.id);
    Get.to(
      () => NRReaderPage(nrId: entry.id),
      binding: ReaderBinding(nrId: entry.id),
    );
  }
}
