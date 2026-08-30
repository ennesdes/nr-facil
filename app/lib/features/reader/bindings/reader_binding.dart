import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/services/search_service.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Binding para injetar dependências do leitor de NRs.
class ReaderBinding extends Bindings {
  final String nrId;
  final String? initialAnchor;

  ReaderBinding({
    required this.nrId,
    this.initialAnchor,
  });

  @override
  void dependencies() {
    Get.lazyPut<NRReaderController>(
      () => NRReaderController(
        nrId: nrId,
        initialAnchor: initialAnchor,
        contentService: Get.find<ContentService>(),
        searchService: Get.isRegistered<SearchService>()
            ? Get.find<SearchService>()
            : null,
      ),
    );
  }
}
