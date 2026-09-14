/// Ignora chamadas repetidas para a mesma chave dentro de uma janela curta.
///
/// Usado para proteger ações de toque idempotentes-por-toque (ex.: favoritar)
/// de double-tap acidental, sem impedir chamadas programáticas deliberadas
/// em sequência (essas devem chamar o serviço diretamente).
class TapDebouncer {
  TapDebouncer._();

  static const _window = Duration(milliseconds: 400);
  static final Map<String, DateTime> _lastCallAt = {};

  /// Executa [action] a menos que a mesma [key] tenha sido chamada há menos
  /// de 400ms.
  static void run(String key, void Function() action) {
    final now = DateTime.now();
    final lastCall = _lastCallAt[key];
    if (lastCall != null && now.difference(lastCall) < _window) {
      return;
    }
    _lastCallAt[key] = now;
    action();
  }
}
