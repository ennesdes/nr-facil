/// Binding para injetar dependências da feature de compliance.
///
/// Registra:
/// - CompanyProfileController (lazyPut — criado sob demanda)
/// - ChecklistController (lazyPut — criado sob demanda)
library;

import 'package:get/get.dart';

import '../../../core/services/compliance_service.dart';
import '../../../core/services/storage_service.dart';
import '../controllers/checklist_controller.dart';
import '../controllers/company_profile_controller.dart';

class ComplianceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompanyProfileController>(
      () => CompanyProfileController(
        storageService: Get.find<StorageService>(),
        complianceService: Get.find<ComplianceService>(),
      ),
    );

    Get.lazyPut<ChecklistController>(
      () => ChecklistController(
        storageService: Get.find<StorageService>(),
        complianceService: Get.find<ComplianceService>(),
      ),
    );
  }
}
