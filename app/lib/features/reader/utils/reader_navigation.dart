import 'package:get/get.dart';
import 'package:nrfacil/features/ads/services/ads_service.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';

/// Navegação centralizada para o leitor — dispara interstitial ao voltar.
class ReaderNavigation {
  ReaderNavigation._();

  /// [initialAnchor] item normativo (ex. 28.1.1), seção, ou `img:<image_src>`.
  static Future<void> open({
    required String nrId,
    String? initialAnchor,
    String? initialHighlightQuery,
  }) async {
    if (Get.isRegistered<AdsService>()) {
      Get.find<AdsService>().onReaderOpened();
    }

    await Get.to(
      () => NRReaderPage(nrId: nrId),
      binding: ReaderBinding(
        nrId: nrId,
        initialAnchor: initialAnchor,
        initialHighlightQuery: initialHighlightQuery,
      ),
    );

    if (Get.isRegistered<AdsService>()) {
      await Get.find<AdsService>().onReaderClosed();
    }
  }
}
