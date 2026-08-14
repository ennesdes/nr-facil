import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../utils/app_logger.dart';

/// StorageService — encapsula GetStorage para storage local.
///
/// Uso: `Get.find<StorageService>().write(key, value)`
/// Bindings: StorageService será injetado como permanent: true
class StorageService extends GetxService {
  late final GetStorage _box;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Inicializar GetStorage — sem nome = default box
    _box = GetStorage();
    await _box.writeIfNull('_initialized', true);
    AppLogger.info('StorageService iniciado');
  }

  /// Escrever valor no storage.
  Future<void> write(String key, dynamic value) async {
    try {
      await _box.write(key, value);
    } catch (e) {
      AppLogger.error('Erro ao escrever em storage: $key = $value', e);
      rethrow;
    }
  }

  /// Ler valor do storage.
  /// Retorna null se chave não existir.
  dynamic read(String key) {
    try {
      return _box.read(key);
    } catch (e) {
      AppLogger.error('Erro ao ler do storage: $key', e);
      return null;
    }
  }

  /// Remover chave do storage.
  Future<void> remove(String key) async {
    try {
      await _box.remove(key);
    } catch (e) {
      AppLogger.error('Erro ao remover do storage: $key', e);
      rethrow;
    }
  }

  /// Limpar todo o storage.
  /// CUIDADO: Esta operação é irreversível.
  Future<void> erase() async {
    try {
      await _box.erase();
      AppLogger.warning('Storage limpo completamente');
    } catch (e) {
      AppLogger.error('Erro ao limpar storage', e);
      rethrow;
    }
  }

  /// Verificar se chave existe no storage.
  bool hasKey(String key) {
    try {
      return _box.hasData(key);
    } catch (e) {
      AppLogger.error('Erro ao verificar chave no storage: $key', e);
      return false;
    }
  }
}
