import 'package:flutter/foundation.dart';

/// Logger centralized para o app.
///
/// Nunca usar print() ou debugPrint() em produção — sempre usar AppLogger.
/// Em release, logs são suprimidos (evita vazamento de URLs/caminhos no logcat).
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
    if (!kDebugMode) return;
    // ignore: avoid_print
    print('$_tag [$level] $message');
  }
}
