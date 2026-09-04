import 'package:nrfacil/core/utils/nr_id_utils.dart';

/// Mensagens exibidas ao usuário — sem paths, exceções ou termos internos.
abstract final class UserMessages {
  static const imageUnavailable = 'Imagem indisponível no momento.';
  static const imageLoadFailed = 'Não foi possível carregar a imagem.';
  static const syncFailed =
      'Não foi possível atualizar as normas. Tente novamente.';
  static const noNetworkNoLocal =
      'Sem conexão e sem dados locais. Tente novamente mais tarde.';
  static const nrRevoked = 'Esta norma foi revogada.';
  static const nrDownloadFailed =
      'Não foi possível baixar a norma. Tente novamente.';
  static const nrLoadFailed =
      'Não foi possível carregar a norma. Tente novamente.';

  static String nrNotAvailable(String nrId) =>
      '${formatNrLabel(nrId)} não está disponível.';

  static String nrNotDownloaded(String nrId) =>
      '${formatNrLabel(nrId)} ainda não foi baixada. '
      'Toque em Baixar para continuar.';

  static String nrLoadRetry(String nrId) =>
      'Não foi possível carregar ${formatNrLabel(nrId)}. '
      'Verifique sua conexão e tente novamente.';
}
