import 'dart:async';

import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';

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

  /// Se está baixando todo o conteúdo offline.
  final isDownloadingAll = false.obs;

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

    await _contentService.syncMetadata();
    unawaited(_contentService.syncSearchIndices());
    unawaited(_contentService.prefetchFavorites());

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

  /// Baixar todas as NRs para uso offline (pacote completo).
  Future<void> downloadAllForOffline() async {
    if (isDownloadingAll.value) return;
    isDownloadingAll.value = true;

    try {
      final ok = await _contentService.syncAllContent();
      if (!ok) {
        AppSnackbar.showError(
          title: 'Download offline',
          message: _contentService.lastError.value ??
              'Não foi possível baixar todo o conteúdo.',
        );
        return;
      }

      AppSnackbar.showSuccess(
        title: 'Download offline',
        message: 'Todas as normas foram baixadas para uso offline.',
      );
    } finally {
      isDownloadingAll.value = false;
    }
  }

  /// Obter entrada de atualização mais recente para uma NR.
  ///
  /// Retorna null se não houver entrada correspondente em app_meta.json.
  /// Usado para exibir detalhes granulares na tela de Atualizações.
  UpdateEntry? getUpdateEntry(String nrId) {
    return _contentService.updateEntryFor(nrId);
  }

  /// Abrir o leitor de uma NR a partir da tela de Atualizações.
  ///
  /// Não marca como vista aqui — o leitor decide isso (banner "NR atualizada"
  /// com CTA "Ver o que mudou"; marca como vista só ao dispensar o banner ou
  /// abrir o CTA). Marcar como vista antes de navegar impediria o banner de
  /// aparecer, já que `hasUpdate` já estaria `false` quando o leitor abrisse.
  void openNrAndMarkSeen(ManifestEntry entry) {
    ReaderNavigation.open(nrId: entry.id);
  }
}
