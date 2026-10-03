import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../utils/app_logger.dart';

/// Coleta desligada em debug (inclui `flutter test`); ligada em profile/release.
Future<void> configureAnalytics() async {
  if (kIsWeb) return;
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
}

/// Firebase Analytics — telas e eventos-chave de produto.
///
/// Catálogo de eventos: `spec/standards/core/analytics.md`.
/// Nunca logar texto normativo ou dado pessoal. Todos os métodos são
/// fail-safe: no-op sem Firebase inicializado e nunca lançam.
class AnalyticsService extends GetxService {
  static const screenHomeNormas = 'home_normas';
  static const screenHomeFavoritos = 'home_favoritos';
  static const screenHomeBusca = 'home_busca';
  static const screenHomeChecklist = 'home_checklist';
  static const screenReader = 'reader';
  static const screenUpdates = 'updates';
  static const screenSettings = 'settings';
  static const screenCompanyProfile = 'company_profile';
  static const screenRevokedNr = 'revoked_nr';

  static const eventOpenNr = 'open_nr';
  static const eventSearch = 'search';
  static const eventFavoriteAdd = 'favorite_add';
  static const eventFavoriteRemove = 'favorite_remove';
  static const eventOpenOfficialPdf = 'open_official_pdf';
  static const eventOpenUpdates = 'open_updates';

  static const paramNrId = 'nr_id';
  static const paramSource = 'source';
  static const paramSearchTerm = 'search_term';
  static const paramResultCount = 'result_count';

  static const sourceNormas = 'normas';
  static const sourceFavoritos = 'favoritos';
  static const sourceBusca = 'busca';
  static const sourceAtualizacoes = 'atualizacoes';
  static const sourceChecklist = 'checklist';
  static const sourceRevogada = 'revogada';
  static const sourceContinuarLeitura = 'continuar_leitura';

  /// Limite de valor de parâmetro do GA4.
  static const maxParamLength = 100;

  /// Instância registrada, ou `null` (testes com bindings parciais).
  static AnalyticsService? get maybe => Get.isRegistered<AnalyticsService>()
      ? Get.find<AnalyticsService>()
      : null;

  Future<void> logScreen(String name) => sendScreen(name);

  Future<void> logOpenNr(String nrId, {required String source}) =>
      sendEvent(eventOpenNr, {paramNrId: nrId, paramSource: source});

  Future<void> logSearch(String term, int resultCount) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return Future.value();
    final clipped = trimmed.length > maxParamLength
        ? trimmed.substring(0, maxParamLength)
        : trimmed;
    return sendEvent(eventSearch, {
      paramSearchTerm: clipped,
      paramResultCount: resultCount,
    });
  }

  Future<void> logFavorite(String nrId, {required bool added}) => sendEvent(
    added ? eventFavoriteAdd : eventFavoriteRemove,
    {paramNrId: nrId},
  );

  Future<void> logOpenOfficialPdf(String nrId) =>
      sendEvent(eventOpenOfficialPdf, {paramNrId: nrId});

  Future<void> logOpenUpdates() => sendEvent(eventOpenUpdates, const {});

  /// Ponto único de envio de evento — sobrescrito pelo fake nos testes.
  @protected
  Future<void> sendEvent(String name, Map<String, Object> parameters) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters.isEmpty ? null : parameters,
      );
    } catch (e, st) {
      AppLogger.error('Falha ao enviar evento $name', e, st);
    }
  }

  /// Ponto único de envio de screen_view — sobrescrito pelo fake nos testes.
  @protected
  Future<void> sendScreen(String name) async {
    if (!_enabled) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: name,
        screenClass: name,
      );
    } catch (e, st) {
      AppLogger.error('Falha ao enviar screen_view $name', e, st);
    }
  }

  bool get _enabled {
    if (kIsWeb) return false;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
