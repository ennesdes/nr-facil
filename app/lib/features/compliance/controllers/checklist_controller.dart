/// Controller para a tela do checklist consolidado.
///
/// Responsabilidades:
/// - Carregar perfil salvo
/// - Cruzar fatores de risco com itens de conformidade
/// - Gerenciar estado de verificação de cada item (persistido)
/// - Oferecer deep-link para o leitor da NR
library;

import 'package:get/get.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/models/company_profile.dart';
import '../../../core/models/compliance_item.dart';
import '../../../core/services/compliance_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/app_logger.dart';

class ChecklistController extends GetxController {
  ChecklistController({
    required this.storageService,
    required this.complianceService,
  });

  final StorageService storageService;
  final ComplianceService complianceService;

  /// Perfil carregado
  late final profile = Rx<CompanyProfile?>(null);

  /// Itens aplicáveis ao perfil
  final applicableItems = <ComplianceItem>[].obs;

  /// Itens agrupados por NR
  final itemsByNr = <String, List<ComplianceItem>>{}.obs;

  /// Estado de verificação por item (chave: "nrId_itemNumber")
  final itemCheckedStatus = <String, bool>{}.obs;

  /// Se está carregando
  final isLoading = true.obs;

  /// Mensagem de erro
  final loadError = RxnString();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadChecklistData();
  }

  /// Carregar dados do checklist.
  Future<void> _loadChecklistData() async {
    try {
      isLoading.value = true;
      loadError.value = null;

      // 1. Carregar perfil salvo
      final profileData = storageService.read(StorageKeys.companyProfile);
      if (profileData == null) {
        loadError.value = 'Perfil não encontrado';
        isLoading.value = false;
        return;
      }

      final loadedProfile = CompanyProfile.fromMap(
        Map<String, dynamic>.from(profileData as Map),
      );
      profile.value = loadedProfile;

      // 2. Buscar itens aplicáveis
      final applicable = complianceService.getApplicableItems(
        loadedProfile.segmentoId,
        loadedProfile.riskFactors,
      );
      applicableItems.value = applicable;

      // 3. Agrupar por NR
      _groupByNr(applicable);

      // 4. Carregar estado de verificação de cada item
      await _loadCheckedStates();

      AppLogger.info(
        'Checklist carregado: ${applicable.length} itens para ${loadedProfile.riskFactors.length} fatores de risco',
      );
    } catch (e, st) {
      AppLogger.error('Erro ao carregar checklist', e, st);
      loadError.value = 'Erro ao carregar checklist: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Agrupar itens por NR.
  void _groupByNr(List<ComplianceItem> items) {
    final grouped = <String, List<ComplianceItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.nrId, () => []).add(item);
    }

    // Ordenar itens dentro de cada NR (aproximadamente por número)
    for (final nr in grouped.keys) {
      grouped[nr]?.sort((a, b) {
        // Tentar ordenar numericamente se possível
        try {
          final aNum = int.parse(a.itemNumber.split(',')[0].split('.')[0]);
          final bNum = int.parse(b.itemNumber.split(',')[0].split('.')[0]);
          return aNum.compareTo(bNum);
        } catch (e) {
          return a.itemNumber.compareTo(b.itemNumber);
        }
      });
    }

    itemsByNr.value = grouped;
  }

  /// Carregar estados de verificação do storage.
  Future<void> _loadCheckedStates() async {
    try {
      for (final item in applicableItems) {
        final key = StorageKeys.complianceItemChecked(item.nrId, item.itemNumber);
        final isChecked = storageService.read(key) as bool? ?? false;
        itemCheckedStatus[_itemKey(item)] = isChecked;
      }
    } catch (e, st) {
      AppLogger.error('Erro ao carregar estados de verificação', e, st);
    }
  }

  /// Alternar estado de verificação de um item.
  Future<void> toggleItemChecked(ComplianceItem item) async {
    try {
      final key = _itemKey(item);
      final currentValue = itemCheckedStatus[key] ?? false;
      final newValue = !currentValue;

      itemCheckedStatus[key] = newValue;

      // Persistir no storage
      final storageKey =
          StorageKeys.complianceItemChecked(item.nrId, item.itemNumber);
      await storageService.write(storageKey, newValue);

      AppLogger.debug(
        'Item ${item.nrId} ${item.itemNumber} marcado como ${newValue ? "verificado" : "pendente"}',
      );
    } catch (e, st) {
      AppLogger.error('Erro ao alternar estado do item', e, st);
    }
  }

  /// Obter estado de verificação de um item.
  bool isItemChecked(ComplianceItem item) {
    return itemCheckedStatus[_itemKey(item)] ?? false;
  }

  /// Recarregar o checklist (perfil + itens aplicáveis + estado de verificação).
  /// Chamado após o perfil da empresa ser editado ou limpo.
  Future<void> reload() => _loadChecklistData();

  /// Desmarcar todos os itens do checklist (mantém o perfil e os itens aplicáveis).
  Future<void> resetAllChecked() async {
    for (final item in applicableItems) {
      itemCheckedStatus[_itemKey(item)] = false;
      final storageKey =
          StorageKeys.complianceItemChecked(item.nrId, item.itemNumber);
      await storageService.write(storageKey, false);
    }
    AppLogger.info('Checklist resetado: todos os itens desmarcados');
  }

  /// Chave única para um item (para usar no mapa de estados).
  String _itemKey(ComplianceItem item) => '${item.nrId}_${item.itemNumber}';

  /// Dados do dataset para disclaimer.
  String get atualizadoEm => complianceService.atualizadoEm;
  String get aviso => complianceService.aviso;

  /// Contar itens verificados.
  int get checkedCount => itemCheckedStatus.values.where((v) => v).length;

  /// Contar itens totais.
  int get totalCount => applicableItems.length;

  /// Percentual de conclusão (0-100).
  int get completionPercentage {
    if (totalCount == 0) return 0;
    return ((checkedCount / totalCount) * 100).round();
  }

  /// Obter lista de NRs em ordem.
  List<String> get nrIds {
    final nrs = itemsByNr.keys.toList();
    nrs.sort();
    return nrs;
  }
}
