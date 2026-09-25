/// Controller para a tela de perfil da empresa.
///
/// Responsabilidades:
/// - Carregar perfil salvo do storage ou criar vazio
/// - Gerenciar estado do formulário (porte, atividade, fatores de risco)
/// - Salvar perfil localmente
/// - Navegar para checklist após salvar
library;

import 'dart:async';

import 'package:get/get.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/models/company_profile.dart';
import '../../../core/services/compliance_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_logger.dart';

class CompanyProfileController extends GetxController {
  CompanyProfileController({
    required this.storageService,
    required this.complianceService,
  });

  final StorageService storageService;
  final ComplianceService complianceService;

  /// Perfil carregado ou em edição
  late final profile = CompanyProfile.empty().obs;

  /// Se está salvando
  final isSaving = false.obs;

  /// Erro ao salvar
  final saveError = RxnString();

  /// Lista de fatores de risco disponíveis
  final availableRiskFactors = <RiskFactor>[].obs;

  /// Lista de segmentos/atividades disponíveis
  final availableSegments = <Segment>[].obs;

  /// Checkbox states para cada fator de risco
  final selectedRiskFactorIds = <String>[].obs;

  /// Porte selecionado
  final porteSelected = ''.obs;

  /// Segmento/atividade selecionado (id de um Segment)
  final segmentoIdSelected = ''.obs;

  /// Se já existe um perfil salvo (controla exibição do botão "Limpar dados").
  final isProfileSaved = false.obs;

  /// Garante que o controller está registrado antes de navegar para a tela.
  static void ensureRegistered() {
    if (!Get.isRegistered<CompanyProfileController>()) {
      Get.put(
        CompanyProfileController(
          storageService: Get.find<StorageService>(),
          complianceService: Get.find<ComplianceService>(),
        ),
      );
    }
  }

  /// Opções de porte
  static const List<String> porteOptions = [
    'Até 10 funcionários',
    '11 a 50 funcionários',
    '51 a 100 funcionários',
    '101 a 500 funcionários',
    'Acima de 500 funcionários',
  ];

  @override
  Future<void> onInit() async {
    super.onInit();
    await complianceService.ensureReady();
    await _loadProfile();
    _loadRiskFactors();
    _loadSegments();
  }

  /// Carregar perfil do storage.
  Future<void> _loadProfile() async {
    try {
      final profileData = storageService.read(StorageKeys.companyProfile);
      if (profileData != null) {
        final loaded = CompanyProfile.fromMap(
          Map<String, dynamic>.from(profileData as Map),
        );
        profile.value = loaded;
        porteSelected.value = loaded.porte;
        segmentoIdSelected.value = loaded.segmentoId;
        selectedRiskFactorIds.value = List.from(loaded.riskFactors);
        isProfileSaved.value = true;
      }
      AppLogger.debug('CompanyProfile carregado do storage');
    } catch (e, st) {
      AppLogger.error('Erro ao carregar CompanyProfile do storage', e, st);
      // Continuar com perfil vazio
    }
  }

  /// Carregar lista de fatores de risco disponíveis.
  void _loadRiskFactors() {
    availableRiskFactors.value = complianceService.getRiskFactors();
  }

  /// Carregar lista de segmentos/atividades disponíveis.
  void _loadSegments() {
    availableSegments.value = complianceService.getSegments();
  }

  /// Marcar/desmarcar um fator de risco.
  void toggleRiskFactor(String factorId) {
    if (selectedRiskFactorIds.contains(factorId)) {
      selectedRiskFactorIds.remove(factorId);
    } else {
      selectedRiskFactorIds.add(factorId);
    }
  }

  /// Verificar se um fator de risco está selecionado.
  bool isRiskFactorSelected(String factorId) {
    return selectedRiskFactorIds.contains(factorId);
  }

  /// Salvar o perfil.
  Future<void> saveProfile() async {
    // Validar campos obrigatórios
    if (porteSelected.value.isEmpty) {
      saveError.value = 'Selecione o porte da empresa';
      return;
    }
    if (segmentoIdSelected.value.isEmpty) {
      saveError.value = 'Selecione a atividade';
      return;
    }

    isSaving.value = true;
    saveError.value = null;

    try {
      final updatedProfile = profile.value.copyWith(
        porte: porteSelected.value,
        segmentoId: segmentoIdSelected.value,
        riskFactors: selectedRiskFactorIds.toList(),
      );

      await storageService.write(
        StorageKeys.companyProfile,
        updatedProfile.toMap(),
      );

      profile.value = updatedProfile;
      isProfileSaved.value = true;
      AppLogger.info('CompanyProfile salvo com sucesso');

      // Fecha esta tela — quem a abriu (HomeController ou ChecklistPage)
      // decide o que fazer em seguida (trocar de aba, recarregar o checklist).
      if (!isClosed) {
        Get.back();
      }
    } catch (e, st) {
      AppLogger.error('Erro ao salvar CompanyProfile', e, st);
      saveError.value = 'Erro ao salvar. Tente novamente.';
    } finally {
      if (!isClosed) {
        isSaving.value = false;
      }
    }
  }

  /// Verificar se há um perfil salvo.
  bool get hasProfile {
    final stored = storageService.read(StorageKeys.companyProfile);
    return stored != null;
  }

  /// Limpar todos os dados do perfil (storage + formulário).
  /// Não navega — o usuário pode preencher um novo perfil na mesma tela.
  Future<void> clearProfile() async {
    try {
      await storageService.remove(StorageKeys.companyProfile);
      profile.value = CompanyProfile.empty();
      porteSelected.value = '';
      segmentoIdSelected.value = '';
      selectedRiskFactorIds.clear();
      isProfileSaved.value = false;
      saveError.value = null;
      AppLogger.info('CompanyProfile removido');
    } catch (e, st) {
      AppLogger.error('Erro ao limpar CompanyProfile', e, st);
    }
  }
}
