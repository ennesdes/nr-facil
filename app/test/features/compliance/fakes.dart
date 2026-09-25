/// Fakes para testes de compliance features.
///
/// Implementações em memória de services para unit tests.
library;

import 'package:nrfacil/core/services/compliance_service.dart';
import 'package:nrfacil/core/services/storage_service.dart';

/// Fake StorageService que usa um Map em memória.
class FakeStorageService extends StorageService {
  final Map<String, dynamic> _storage = {};

  @override
  // ignore: must_call_super
  Future<void> onInit() async {
    // Intencionalmente NÃO chama super.onInit(): o pai inicializaria um
    // GetStorage real (precisa de path_provider, indisponível em unit test).
    // Este fake mantém tudo em memória via _storage.
  }

  @override
  Future<void> write(String key, dynamic value) async {
    _storage[key] = value;
  }

  @override
  dynamic read(String key) {
    return _storage[key];
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> erase() async {
    _storage.clear();
  }

  @override
  bool hasKey(String key) {
    return _storage.containsKey(key);
  }

  /// Método de teste para limpar storage
  void clear() {
    _storage.clear();
  }

  /// Método de teste para obter conteúdo do storage
  Map<String, dynamic> getStorageContents() => Map.from(_storage);
}

/// Fake ComplianceService com dataset pré-configurado para testes.
class FakeComplianceService extends ComplianceService {
  /// Criar fake com dados pré-carregados
  FakeComplianceService({
    required this.mockDataset,
  });

  late final ComplianceDataset mockDataset;

  @override
  Future<void> ensureReady() async {
    // Não delegar ao pai — evita carregar compliance.json do bundle nos testes.
    dataset = mockDataset;
    isLoaded.value = true;
    loadError.value = null;
  }

  @override
  // ignore: must_call_super
  Future<void> onInit() async {
    await ensureReady();
  }
}
