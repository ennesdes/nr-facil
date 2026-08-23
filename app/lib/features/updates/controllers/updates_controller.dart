import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
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

  /// Se está verificando atualizações no momento (acionado pelo botão manual).
  final isChecking = false.obs;

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

  /// Verificar atualizações manualmente — força busca do manifest remoto.
  ///
  /// Usa `lastSyncedAt` para distinguir "verificado, sem novidades" de
  /// "não foi possível conectar" (nesse caso `sync()` retorna sucesso mesmo
  /// assim, para não bloquear o modo offline).
  Future<void> checkForUpdates() async {
    if (isChecking.value) return;
    isChecking.value = true;

    final previousSyncedAt = _contentService.lastSyncedAt.value;
    final countBefore = _contentService.updatedNrs.length;

    await _contentService.sync();

    isChecking.value = false;

    final reachedNetwork =
        _contentService.lastSyncedAt.value != previousSyncedAt;

    if (!reachedNetwork) {
      AppSnackbar.showError(
        title: 'Verificar atualizações',
        message: _contentService.lastError.value ??
            'Não foi possível conectar. Tente novamente mais tarde.',
      );
      return;
    }

    final newCount = _contentService.updatedNrs.length - countBefore;
    final message = newCount > 0
        ? (newCount == 1
            ? '1 nova atualização encontrada.'
            : '$newCount novas atualizações encontradas.')
        : 'Nenhuma atualização nova. Suas normas estão em dia.';

    if (newCount > 0) {
      AppSnackbar.showSuccess(title: 'Verificar atualizações', message: message);
    } else {
      AppSnackbar.showInfo(title: 'Verificar atualizações', message: message);
    }
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
