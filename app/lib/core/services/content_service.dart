import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_config.dart';
import '../constants/storage_keys.dart';
import '../models/app_meta.dart';
import '../models/manifest.dart';
import '../models/nr_index.dart';
import '../models/nr_structure.dart';
import '../models/reading_history_entry.dart';
import '../models/search_chunk.dart';
import '../utils/app_logger.dart';

/// ContentService — sincronizar e cache de NRs offline.
///
/// Responsabilidades:
/// - Baixar manifest.json do GitHub raw periodicamente
/// - Comparar hash por NR e fazer download incremental de .md + assets
/// - Cache em path_provider (getApplicationDocumentsDirectory)
/// - Funcionar 100% offline após primeiro sync bem-sucedido
/// - Detectar atualização: last_synced_hash vs last_seen_hash
///
/// Usar via GetX: `Get.find<ContentService>()`
/// Bindings: ContentService será injetado como permanent: true em Binding
class ContentService extends GetxService {
  late final http.Client _httpClient;
  late final Directory _cacheDir;

  /// Estado reativo — manifest atualmente em memória
  final manifest = Rxn<Manifest>();

  /// Estado reativo — feed de atualizações (app_meta.json) em memória
  final appMeta = Rxn<AppMeta>();

  /// Estado reativo — se está sincronizando no momento
  final isSyncing = false.obs;

  /// Estado reativo — mensagem de erro da última operação (null = sucesso)
  final lastError = Rxn<String>();

  /// Timestamp da última sincronização bem-sucedida
  final lastSyncedAt = Rxn<DateTime>();

  /// Lista reativa de IDs de NRs favoritadas (ordem de exibição importa)
  final favoriteIds = <String>[].obs;

  /// Contagem reativa de atualizações não lidas
  final unreadUpdatesCount = 0.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _httpClient = http.Client();
    _cacheDir = await getApplicationDocumentsDirectory();
    AppLogger.info('ContentService iniciado. Cache em: ${_cacheDir.path}');

    // Carregar manifest do cache local ao iniciar
    await _loadManifestFromCache();

    // Carregar favoritos do storage local
    _loadFavorites();

    // Atualizar contagem de atualizações não lidas
    _updateUnreadCount();
  }

  @override
  void onClose() {
    _httpClient.close();
    super.onClose();
  }

  /// Sincronizar — baixar manifest remoto e fazer download incremental de NRs.
  ///
  /// Fluxo:
  /// 1. Baixar manifest.json do GitHub raw
  /// 2. Para cada NR: comparar hash remoto vs cache local (via StorageKeys.nrLastSyncedHash)
  /// 3. Se diferente: baixar .md + assets (pasta assets/)
  /// 4. Salvar manifest no cache
  /// 5. Atualizar lastSyncedAt
  ///
  /// Tratamento de erro:
  /// - Falha de rede: continuar com manifest do cache local (offline fallback)
  /// - Manifest inválido: loga erro, não atualiza, mantém versão anterior
  /// - Falha numa NR específica: tenta não bloqueia outras NRs (mas por enquanto, falha a sincronização)
  Future<bool> sync() async {
    if (isSyncing.value) {
      AppLogger.warning('Sincronização já em andamento');
      return false;
    }

    isSyncing.value = true;
    lastError.value = null;

    try {
      AppLogger.info('Iniciando sincronização de manifest...');

      // Baixar manifest remoto
      final remoteManifest = await _downloadManifest();
      if (remoteManifest == null) {
        // Falha de rede — usar cache local se disponível
        AppLogger.warning('Falha ao sincronizar manifest remoto. Usando cache local.');
        if (manifest.value == null) {
          lastError.value =
              'Falha de rede e sem cache local. Tente novamente mais tarde.';
          return false;
        }
        return true; // Offline mode OK
      }

      // Atualizar manifest em memória
      manifest.value = remoteManifest;

      // Baixar app_meta.json (feed de atualizações) em paralelo
      // Falha não bloqueia o sync do manifest, que é essencial
      await _downloadAppMeta();

      // Para cada NR: verificar se precisa atualizar e fazer download incremental
      for (final nrEntry in remoteManifest.nrs) {
        // Pular NRs revogadas — não fazer download
        if (nrEntry.isRevoked) {
          AppLogger.info('NR ${nrEntry.id} está revogada. Pulando download.');
          continue;
        }

        // Verificar se precisa sincronizar
        final localHash =
            GetStorage().read(StorageKeys.nrLastSyncedHash(nrEntry.id));
        if (nrEntry.hash == localHash) {
          AppLogger.debug('NR ${nrEntry.id} já sincronizada (hash igual)');
          continue;
        }

        AppLogger.info('Sincronizando NR ${nrEntry.id}...');
        await _downloadNr(nrEntry);
      }

      // Salvar manifest no cache
      await _saveManifestToCache(remoteManifest);

      // Atualizar timestamp
      lastSyncedAt.value = DateTime.now();
      GetStorage().write(StorageKeys.lastSyncedAt, lastSyncedAt.value!.toIso8601String());

      // Atualizar contagem de atualizações
      _updateUnreadCount();

      AppLogger.info('Sincronização concluída com sucesso');
      return true;
    } catch (e, st) {
      lastError.value = 'Erro na sincronização: $e';
      AppLogger.error('Erro na sincronização', e, st);
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Baixa uma NR específica sob demanda (quando não está em cache).
  Future<bool> downloadNrIfNeeded(String nrId) async {
    final entry = manifest.value?.findNr(nrId);
    if (entry == null) {
      lastError.value = 'NR $nrId não encontrada no manifest';
      return false;
    }
    if (entry.isRevoked) {
      lastError.value = 'NR $nrId está revogada';
      return false;
    }

    final localHash = GetStorage().read(StorageKeys.nrLastSyncedHash(nrId));
    if (entry.hash == localHash) {
      return true;
    }

    try {
      await _downloadNr(entry);
      return true;
    } catch (e, st) {
      lastError.value = 'Falha ao baixar $nrId: $e';
      AppLogger.error('Erro no download sob demanda de $nrId', e, st);
      return false;
    }
  }

  /// Texto amigável do status de sincronização.
  String? get lastSyncedLabel {
    final synced = lastSyncedAt.value;
    if (synced == null) return null;
    final diff = DateTime.now().difference(synced);
    if (diff.inMinutes < 1) return 'Sincronizado agora';
    if (diff.inHours < 1) return 'Sincronizado há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Sincronizado há ${diff.inHours} h';
    return 'Sincronizado há ${diff.inDays} dia(s)';
  }

  /// Download o conteúdo de uma NR (.md + pasta assets/).
  ///
  /// Cria estrutura em cache:
  /// - ${cacheDir}/content/nr-06/
  ///   - nr-06.md
  ///   - assets/
  ///     - images/
  ///     - tables/
  ///     - pages/
  ///
  /// Ao final, atualiza StorageKeys.nrLastSyncedHash para rastrear que essa versão foi baixada.
  Future<void> _downloadNr(ManifestEntry entry) async {
    try {
      final nrDir = Directory('${_cacheDir.path}/content/${entry.id}');
      final assetsDir = Directory('${nrDir.path}/assets');

      // Criar estrutura de pastas
      if (!nrDir.existsSync()) {
        nrDir.createSync(recursive: true);
      }
      if (!assetsDir.existsSync()) {
        assetsDir.createSync(recursive: true);
      }

      // Baixar .md principal
      await _downloadFile(
        url: entry.url,
        savePath: '${nrDir.path}/${entry.id}.md',
        retries: AppConfig.maxRetries,
      );

      // Baixar JSONs auxiliares (índice, busca, estrutura)
      for (final jsonName in [
        'index.json',
        'search_index.json',
        'structure.json',
      ]) {
        try {
          await _downloadFile(
            url: '${AppConfig.contentBaseUrl}/${entry.id}/$jsonName',
            savePath: '${nrDir.path}/$jsonName',
            retries: AppConfig.maxRetries,
          );
        } catch (e) {
          AppLogger.warning(
            'Falha ao baixar $jsonName de ${entry.id}: $e',
          );
        }
      }

      // Baixar assets (images, tables, pages) referenciados no markdown
      await _downloadAssets(nrDir, entry.id);

      // Marcar como sincronizado
      GetStorage().write(StorageKeys.nrLastSyncedHash(entry.id), entry.hash);

      AppLogger.info('NR ${entry.id} sincronizada com sucesso');
    } catch (e, st) {
      AppLogger.error('Erro ao baixar NR ${entry.id}', e, st);
      rethrow; // Propagar erro
    }
  }

  /// Download dos assets (imagens/tabelas) referenciados no `.md` de uma NR.
  ///
  /// GitHub raw não suporta listing de diretório, então não há como descobrir
  /// os arquivos de assets de uma NR além do que o próprio `.md` referencia.
  /// Estratégia: ler o `.md` já baixado e extrair todo caminho relativo usado
  /// em sintaxe de imagem markdown `![alt](assets/...)`, baixando cada um.
  ///
  /// Falha em um asset individual não aborta a sincronização da NR — a NR
  /// deve ficar legível mesmo que uma imagem específica falhe.
  static final _mdImageRefPattern = RegExp(r'!\[[^\]]*\]\((assets/[^)\s]+)\)');

  Future<void> _downloadAssets(Directory nrDir, String nrId) async {
    final mdFile = File('${nrDir.path}/$nrId.md');
    if (!mdFile.existsSync()) return;

    final content = await mdFile.readAsString();
    final relativePaths = _mdImageRefPattern
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toSet();

    for (final relativePath in relativePaths) {
      try {
        final savePath = '${nrDir.path}/$relativePath';
        final saveDir = File(savePath).parent;
        if (!saveDir.existsSync()) {
          saveDir.createSync(recursive: true);
        }

        await _downloadFile(
          url: '${AppConfig.contentBaseUrl}/$nrId/$relativePath',
          savePath: savePath,
          retries: AppConfig.maxRetries,
        );
      } catch (e) {
        AppLogger.warning('Falha ao baixar asset $relativePath de $nrId: $e');
        // Continuar com os demais assets — uma imagem faltando não impede a leitura do texto
      }
    }
  }

  /// Baixar um arquivo remoto para o cache local.
  ///
  /// Implementa retry com backoff exponencial.
  /// Se todas as tentativas falharem, lança exceção.
  Future<void> _downloadFile({
    required String url,
    required String savePath,
    required int retries,
  }) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        AppLogger.debug('Baixando: $url (tentativa $attempt)');

        final response = await _httpClient
            .get(Uri.parse(url))
            .timeout(Duration(seconds: AppConfig.syncTimeoutSeconds));

        if (response.statusCode == 200) {
          final file = File(savePath);
          await file.writeAsBytes(response.bodyBytes);
          AppLogger.debug('Arquivo salvo: $savePath');
          return; // Sucesso
        } else if (response.statusCode == 404) {
          throw HttpException(
              'Arquivo não encontrado: $url (404)');
        } else {
          throw HttpException(
              'HTTP ${response.statusCode}: $url');
        }
      } catch (e) {
        attempt++;
        if (attempt >= retries) {
          AppLogger.error('Falha permanente após $retries tentativas: $url');
          rethrow;
        }
        // Esperar antes de retentar
        await Future.delayed(
          Duration(seconds: AppConfig.retryDelaySeconds),
        );
      }
    }
  }

  /// Baixar manifest.json do GitHub raw.
  ///
  /// Retorna null se falhar (erro de rede, timeout, etc).
  /// Lança ManifestParseException se o JSON for inválido.
  Future<Manifest?> _downloadManifest() async {
    try {
      AppLogger.debug('Baixando manifest de: ${AppConfig.manifestUrl}');

      final response = await _httpClient
          .get(Uri.parse(AppConfig.manifestUrl))
          .timeout(Duration(seconds: AppConfig.syncTimeoutSeconds));

      if (response.statusCode != 200) {
        AppLogger.warning(
            'Falha ao baixar manifest: HTTP ${response.statusCode}');
        return null;
      }

      // Parse JSON
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteManifest = Manifest.fromMap(jsonMap);

      AppLogger.info(
          'Manifest baixado: ${remoteManifest.nrs.length} NRs encontradas');
      return remoteManifest;
    } on TimeoutException catch (e) {
      AppLogger.warning('Timeout ao baixar manifest: $e');
      return null;
    } on SocketException catch (e) {
      AppLogger.warning('Erro de rede ao baixar manifest: $e');
      return null;
    } catch (e, st) {
      AppLogger.error('Erro ao baixar manifest', e, st);
      return null;
    }
  }

  /// Baixar app_meta.json do GitHub raw.
  ///
  /// Retorna silenciosamente em caso de falha (erro de rede, timeout, JSON inválido).
  /// Falha não deve interromper o sync do manifest, que é o dado essencial.
  /// Chama factory AppMeta.fromJson, que lança AppMetaParseException em caso de parse error.
  Future<void> _downloadAppMeta() async {
    try {
      AppLogger.debug('Baixando app_meta de: ${AppConfig.appMetaUrl}');

      final response = await _httpClient
          .get(Uri.parse(AppConfig.appMetaUrl))
          .timeout(Duration(seconds: AppConfig.syncTimeoutSeconds));

      if (response.statusCode != 200) {
        AppLogger.warning(
            'Falha ao baixar app_meta: HTTP ${response.statusCode}');
        return;
      }

      // Parse JSON
      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      appMeta.value = AppMeta.fromJson(jsonMap);

      AppLogger.info(
          'AppMeta baixado: ${appMeta.value?.updates.length ?? 0} atualizações encontradas');
    } on TimeoutException catch (e) {
      AppLogger.warning('Timeout ao baixar app_meta: $e');
      // Continuar sem falhar
    } on SocketException catch (e) {
      AppLogger.warning('Erro de rede ao baixar app_meta: $e');
      // Continuar sem falhar
    } catch (e, st) {
      AppLogger.warning('Erro ao baixar/parsear app_meta: $e');
      AppLogger.debug('Stack trace: $st');
      // Continuar sem falhar — feed de atualizações é um "nice to have"
    }
  }

  /// Carregar manifest do cache local.
  ///
  /// Executado no onInit() para restaurar estado anterior.
  /// Se cache estiver corrompido, loga aviso e continua com manifest vazio.
  Future<void> _loadManifestFromCache() async {
    try {
      final manifestFile =
          File('${_cacheDir.path}/manifest.json');

      if (!manifestFile.existsSync()) {
        AppLogger.debug('Sem manifest.json em cache (primeira execução?)');
        return;
      }

      final content = await manifestFile.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      manifest.value = Manifest.fromMap(jsonMap);

      // Restaurar timestamp
      final lastSyncedStr = GetStorage().read(StorageKeys.lastSyncedAt) as String?;
      if (lastSyncedStr != null) {
        lastSyncedAt.value = DateTime.parse(lastSyncedStr);
      }

      AppLogger.info(
          'Manifest carregado do cache: ${manifest.value?.nrs.length ?? 0} NRs');
    } catch (e) {
      AppLogger.warning('Falha ao carregar manifest do cache: $e');
      // Continuar — cache pode estar corrompido
    }
  }

  /// Salvar manifest no cache local.
  Future<void> _saveManifestToCache(Manifest manifest) async {
    try {
      final manifestFile =
          File('${_cacheDir.path}/manifest.json');

      if (!manifestFile.parent.existsSync()) {
        manifestFile.parent.createSync(recursive: true);
      }

      final jsonMap = manifest.toMap();
      await manifestFile.writeAsString(jsonEncode(jsonMap));

      AppLogger.debug('Manifest salvo em cache');
    } catch (e, st) {
      AppLogger.error('Erro ao salvar manifest em cache', e, st);
      rethrow;
    }
  }

  /// Ler conteúdo de uma NR (.md) do cache local.
  ///
  /// Retorna null se arquivo não existir (NR não foi sincronizada).
  /// Lança exceção se houver erro de I/O.
  Future<String?> readNrContent(String nrId) async {
    try {
      final mdFile = File('${_cacheDir.path}/content/$nrId/$nrId.md');

      if (!mdFile.existsSync()) {
        AppLogger.warning('NR $nrId não encontrada em cache');
        return null;
      }

      return await mdFile.readAsString();
    } catch (e, st) {
      AppLogger.error('Erro ao ler conteúdo de NR $nrId', e, st);
      rethrow;
    }
  }

  /// Obter caminho local de um asset (imagem, tabela, etc) de uma NR.
  ///
  /// Retorna caminho absoluto. Verificar com File(path).exists() antes de usar.
  String getAssetPath(String nrId, String assetPath) {
    return '${_cacheDir.path}/content/$nrId/assets/$assetPath';
  }

  /// Verificar se há atualização para uma NR.
  ///
  /// Novo = (hash remoto no manifest) ≠ (last_seen_hash local)
  /// Usar isso para exibir badge 🆕 em favoritos/listas.
  bool hasUpdate(String nrId) {
    final entry = manifest.value?.findNr(nrId);
    if (entry == null) return false;

    final lastSeenHash =
        GetStorage().read(StorageKeys.nrLastSeenHash(nrId)) as String?;
    return entry.hash != lastSeenHash;
  }

  /// Marcar NR como vista (atualizar last_seen_hash).
  ///
  /// Chamar ao abrir o leitor de uma NR.
  void markNrAsSeen(String nrId) {
    final entry = manifest.value?.findNr(nrId);
    if (entry != null) {
      GetStorage().write(StorageKeys.nrLastSeenHash(nrId), entry.hash);
      AppLogger.debug('NR $nrId marcada como vista');
      _updateUnreadCount(); // Atualizar contagem após marcar como visto
    }
  }

  /// Obter lista de NRs com atualizações pendentes (não revogadas).
  ///
  /// Retorna lista vazia se nenhuma atualização disponível ou se manifest não está carregado.
  List<ManifestEntry> get updatedNrs {
    if (manifest.value == null) return [];
    return manifest.value!.nrs
        .where((entry) => !entry.isRevoked && hasUpdate(entry.id))
        .toList();
  }

  /// Atualizar contagem reativa de atualizações não lidas.
  ///
  /// Chamado internamente após marcar NR como vista ou carregar manifest.
  void _updateUnreadCount() {
    unreadUpdatesCount.value = updatedNrs.length;
  }

  /// Buscar entrada de atualização mais recente para uma NR.
  ///
  /// build_app_meta.py sempre acrescenta entradas novas ao final de `updates[]`
  /// (ordem cronológica de inserção) — não é preciso reordenar por `createdAt`,
  /// só pegar a última ocorrência da NR na lista. Retorna null se nenhuma
  /// entrada for encontrada.
  UpdateEntry? updateEntryFor(String nrId) {
    final entries = appMeta.value?.updates;
    if (entries == null) return null;

    for (var i = entries.length - 1; i >= 0; i--) {
      if (entries[i].nrId == nrId) return entries[i];
    }
    return null;
  }

  /// Comparação semver simples para determinar se atualização obrigatória é necessária.
  ///
  /// Formato esperado: major.minor.patch (ex: "1.2.0", "1.0.5")
  /// Retorna true se installedVersion < minVersion.
  bool _compareVersions(String installedVersion, String minVersion) {
    try {
      final installed = installedVersion.split('.');
      final minimum = minVersion.split('.');

      // Comparar major.minor.patch
      for (int i = 0; i < 3; i++) {
        final installedPart = i < installed.length
            ? int.tryParse(installed[i]) ?? 0
            : 0;
        final minimumPart =
            i < minimum.length ? int.tryParse(minimum[i]) ?? 0 : 0;

        if (installedPart < minimumPart) return true;
        if (installedPart > minimumPart) return false;
      }

      return false; // Versões iguais, não requer update obrigatório
    } catch (e) {
      AppLogger.warning('Erro ao comparar versões: $e');
      return false; // Em caso de erro, não bloquear
    }
  }

  /// Verificar se atualização obrigatória é necessária.
  ///
  /// Compara a versão instalada do app (via PackageInfo) com
  /// minAppVersion do app_meta.json. Retorna false se app_meta
  /// ainda não foi baixado ou se a versão instalada >= min_app_version.
  Future<bool> get forcedUpdateRequired async {
    if (appMeta.value == null) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return _compareVersions(
        packageInfo.version,
        appMeta.value!.minAppVersion,
      );
    } catch (e) {
      AppLogger.warning('Erro ao verificar versão do app: $e');
      return false; // Em caso de erro, não bloquear o app
    }
  }

  /// Ler structure.json de uma NR do cache local.
  ///
  /// Retorna null se arquivo não existir ou estiver corrompido.
  Future<NrStructure?> readNrStructure(String nrId) async {
    try {
      final structureFile =
          File('${_cacheDir.path}/content/$nrId/structure.json');

      if (!structureFile.existsSync()) {
        AppLogger.debug('structure.json de $nrId não encontrado em cache');
        return null;
      }

      final content = await structureFile.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      return NrStructure.fromMap(jsonMap);
    } catch (e, st) {
      AppLogger.error('Erro ao ler structure.json de NR $nrId', e, st);
      return null;
    }
  }

  /// Ler índice de navegação de uma NR (index.json) do cache local.
  ///
  /// Retorna NrIndex com headings vazios se arquivo não existir.
  /// Lança exceção se houver erro de I/O.
  Future<NrIndex> readNrIndex(String nrId) async {
    try {
      final indexFile = File('${_cacheDir.path}/content/$nrId/index.json');

      if (!indexFile.existsSync()) {
        AppLogger.debug('Índice de $nrId não encontrado em cache');
        return NrIndex(headings: []);
      }

      final content = await indexFile.readAsString();
      final jsonMap = jsonDecode(content) as Map<String, dynamic>;
      return NrIndex.fromMap(jsonMap);
    } catch (e, st) {
      AppLogger.error('Erro ao ler índice de NR $nrId', e, st);
      // Retornar índice vazio em caso de erro
      return NrIndex(headings: []);
    }
  }

  /// Ler índice de busca (search_index.json) de uma NR do cache local.
  ///
  /// Retorna lista vazia de SearchChunk se arquivo não existir.
  /// Lança exceção se houver erro de I/O.
  Future<List<SearchChunk>> readSearchIndex(String nrId) async {
    try {
      final searchFile = File('${_cacheDir.path}/content/$nrId/search_index.json');

      if (!searchFile.existsSync()) {
        AppLogger.debug('Índice de busca de $nrId não encontrado em cache');
        return [];
      }

      final content = await searchFile.readAsString();
      final jsonList = jsonDecode(content) as List<dynamic>;
      return jsonList
          .map((e) => SearchChunk.fromMap(
              e is Map<String, dynamic> ? e : <String, dynamic>{}))
          .toList();
    } catch (e, st) {
      AppLogger.error('Erro ao ler índice de busca de NR $nrId', e, st);
      // Retornar lista vazia em caso de erro
      return [];
    }
  }

  /// Carregar lista de favoritos do storage local.
  void _loadFavorites() {
    try {
      final savedList = GetStorage().read<List>(StorageKeys.favoriteNrs);
      if (savedList != null) {
        favoriteIds.value =
            savedList.map((item) => item.toString()).toList();
        AppLogger.debug(
            'Favoritos carregados: ${favoriteIds.length} NRs');
      }
    } catch (e) {
      AppLogger.warning('Erro ao carregar favoritos: $e');
      // Continuar com lista vazia
    }
  }

  /// Verificar se uma NR é favorita.
  bool isFavorite(String nrId) {
    return favoriteIds.contains(nrId);
  }

  /// Adicionar ou remover uma NR dos favoritos.
  ///
  /// Atualiza lista reativa e persiste em storage.
  void toggleFavorite(String nrId) {
    if (favoriteIds.contains(nrId)) {
      favoriteIds.remove(nrId);
      AppLogger.debug('NR $nrId removida dos favoritos');
    } else {
      favoriteIds.add(nrId);
      AppLogger.debug('NR $nrId adicionada aos favoritos');
    }
    GetStorage().write(StorageKeys.favoriteNrs, favoriteIds.toList());
  }

  /// Reordenar favoritos (usado em ReorderableListView.onReorderItem).
  ///
  /// `newIndex` já vem ajustado pelo `onReorderItem` — não reajustar aqui.
  /// Atualiza ordem e persiste em storage.
  void reorderFavorites(int oldIndex, int newIndex) {
    final item = favoriteIds.removeAt(oldIndex);
    favoriteIds.insert(newIndex, item);
    GetStorage().write(StorageKeys.favoriteNrs, favoriteIds.toList());
    AppLogger.debug('Favoritos reordenados: índice $oldIndex para $newIndex');
  }

  /// Obter ID da última NR aberta (para "Continuar leitura").
  ///
  /// Retorna null se nenhuma NR foi aberta.
  String? get lastOpenedNrId {
    return GetStorage().read<String?>(StorageKeys.lastOpenedNr);
  }

  /// Adicionar ou atualizar entrada no histórico de leitura.
  ///
  /// Se a NR já existe no histórico, atualiza timestamp e posição de scroll.
  /// Mantém as últimas ~20 NRs lidas (FIFO).
  void addToReadingHistory(String nrId, {double scrollPosition = 0.0}) {
    try {
      final savedList = GetStorage().read<List>(StorageKeys.readingHistory);
      final historyList = savedList ?? [];

      // Converter para ReadingHistoryEntry
      final history = historyList
          .map((item) => ReadingHistoryEntry.fromMap(
              item is Map<String, dynamic> ? item : <String, dynamic>{}))
          .toList();

      // Remover entrada anterior se existir (para reposicionar no topo)
      history.removeWhere((entry) => entry.nrId == nrId);

      // Adicionar nova entrada no topo
      history.insert(
        0,
        ReadingHistoryEntry(
          nrId: nrId,
          lastAccessedAt: DateTime.now(),
          scrollPosition: scrollPosition,
        ),
      );

      // Manter apenas as últimas 20 entradas
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      // Salvar em storage
      final mapList = history.map((e) => e.toMap()).toList();
      GetStorage().write(StorageKeys.readingHistory, mapList);

      AppLogger.debug('NR $nrId adicionada ao histórico de leitura');
    } catch (e, st) {
      AppLogger.error('Erro ao adicionar ao histórico de leitura', e, st);
      // Continuar sem falhar
    }
  }

  /// Obter histórico de leitura (ordenado por acesso recente).
  ///
  /// Retorna lista vazia se nada foi lido.
  List<ReadingHistoryEntry> getReadingHistory() {
    try {
      final savedList = GetStorage().read<List>(StorageKeys.readingHistory);
      if (savedList == null) return [];

      return savedList
          .map((item) => ReadingHistoryEntry.fromMap(
              item is Map<String, dynamic> ? item : <String, dynamic>{}))
          .toList();
    } catch (e, st) {
      AppLogger.error('Erro ao carregar histórico de leitura', e, st);
      return [];
    }
  }

  /// Obter posição de scroll salva para uma NR.
  ///
  /// Retorna 0.0 se nenhuma posição foi salva.
  double getScrollPosition(String nrId) {
    try {
      final history = getReadingHistory();
      final entry = history.firstWhere(
        (e) => e.nrId == nrId,
        orElse: () => ReadingHistoryEntry(
          nrId: nrId,
          lastAccessedAt: DateTime.now(),
        ),
      );
      return entry.scrollPosition;
    } catch (e) {
      AppLogger.debug('Sem posição de scroll salva para $nrId');
      return 0.0;
    }
  }

  /// Salvar posição de scroll para uma NR.
  ///
  /// Atualiza entrada existente no histórico.
  void saveScrollPosition(String nrId, double scrollPosition) {
    try {
      final savedList = GetStorage().read<List>(StorageKeys.readingHistory);
      final historyList = savedList ?? [];

      final history = historyList
          .map((item) => ReadingHistoryEntry.fromMap(
              item is Map<String, dynamic> ? item : <String, dynamic>{}))
          .toList();

      // Encontrar e atualizar entrada
      final index = history.indexWhere((e) => e.nrId == nrId);
      if (index >= 0) {
        history[index] = history[index].copyWith(scrollPosition: scrollPosition);
        final mapList = history.map((e) => e.toMap()).toList();
        GetStorage().write(StorageKeys.readingHistory, mapList);
        AppLogger.debug('Posição de scroll salva para $nrId: $scrollPosition');
      }
    } catch (e, st) {
      AppLogger.error('Erro ao salvar posição de scroll', e, st);
      // Continuar sem falhar
    }
  }
}
