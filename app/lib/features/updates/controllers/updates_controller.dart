import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/sync_progress.dart';
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

  /// Se está baixando todo o conteúdo offline (estado global no [ContentService]).
  bool get isBulkDownloading => _contentService.isBulkDownloading;

  Rxn<BulkSyncProgress> get bulkSyncProgress =>
      _contentService.bulkSyncProgress;

  /// Exibe botão "Baixar tudo" enquanto houver NRs pendentes de download offline.
  RxBool get offlineDownloadNeeded => _contentService.offlineDownloadNeeded;

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
        message:
            _contentService.lastError.value ??
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
      AppSnackbar.showSuccess(
        title: 'Verificar atualizações',
        message: message,
      );
    } else {
      AppSnackbar.showInfo(title: 'Verificar atualizações', message: message);
    }
  }

  /// Baixar todas as NRs para uso offline (pacote completo).
  Future<void> downloadAllForOffline() async {
    if (_contentService.isBulkDownloading) return;

    final result = await _contentService.syncAllContent();
    updatedNrs.value = _contentService.updatedNrs;

    if (result.cancelled) {
      final total = result.totalToDownload;
      final done = result.downloadedCount;
      final message = done == 0
          ? 'Download cancelado.'
          : total > 0
          ? 'Download cancelado. $done de $total normas baixadas.'
          : 'Download cancelado. $done normas baixadas.';
      AppSnackbar.showInfo(title: 'Download offline', message: message);
      return;
    }

    if (!result.success) {
      AppSnackbar.showError(
        title: 'Download offline',
        message:
            _contentService.lastError.value ??
            'Não foi possível baixar todo o conteúdo.',
      );
      return;
    }

    if (!result.reachedNetwork && result.downloadedCount == 0) {
      AppSnackbar.showError(
        title: 'Download offline',
        message:
            _contentService.lastError.value ??
            'Não foi possível conectar. Verifique sua internet.',
      );
      return;
    }

    final pendingUpdates = _contentService.updatedNrs.length;
    final message = switch ((result.downloadedCount, pendingUpdates)) {
      (0, 0) => 'Todas as normas já estavam baixadas e em dia.',
      (0, _) =>
        'Seu conteúdo offline já está atualizado. '
            'Abra cada norma para revisar as mudanças.',
      (_, 0) =>
        result.downloadedCount == 1
            ? '1 norma baixada para uso offline.'
            : '${result.downloadedCount} normas baixadas para uso offline.',
      (_, _) =>
        result.downloadedCount == 1
            ? '1 norma baixada. Abra-a para revisar as mudanças.'
            : '${result.downloadedCount} normas baixadas. '
                  'Abra-as para revisar as mudanças.',
    };

    if (result.downloadedCount > 0) {
      AppSnackbar.showSuccess(title: 'Download offline', message: message);
    } else {
      AppSnackbar.showInfo(title: 'Download offline', message: message);
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

  /// Exibe confirmação e cancela o download em massa, se o usuário confirmar.
  Future<void> confirmCancelDownload(BuildContext context) async {
    if (!_contentService.isBulkDownloading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar download?'),
        content: const Text(
          'O download será interrompido. As normas já baixadas '
          'continuarão disponíveis offline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar baixando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar download'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _contentService.cancelBulkSync();
    }
  }
}
