/// Logger centralized para o app.
///
/// Nunca usar print() ou debugPrint() em produção — sempre usar AppLogger.
/// Em produção, logs vão para arquivo ou serviço de observabilidade.
/// Em desenvolvimento, logs vão para console.
class AppLogger {
  static const String _tag = '[NRFácil]';

  /// Log info — para eventos normais (sync iniciado, NR baixada, etc).
  static void info(String message) {
    _log('INFO', message);
  }

  /// Log warning — para situações inesperadas mas recuperáveis (falha de rede, cache corrupto).
  static void warning(String message) {
    _log('WARN', message);
  }

  /// Log error — para falhas críticas (manifest.json inválido).
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      _log('ERROR', 'Causa: $error');
    }
    if (stackTrace != null) {
      _log('ERROR', 'Stack: $stackTrace');
    }
  }

  /// Log debug — apenas em desenvolvimento.
  static void debug(String message) {
    _log('DEBUG', message);
  }

  static void _log(String level, String message) {
    // Em produção, isso entraria em um serviço de logging.
    // Por enquanto, vamos apenas imprimir com tag.
    // ignore: avoid_print
    print('$_tag [$level] $message');
  }
}
