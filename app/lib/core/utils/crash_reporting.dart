import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Configura captura de crashes fatais e erros assíncronos no Firebase Crashlytics.
///
/// Só deve ser chamado após [Firebase.initializeApp] ter sucesso.
/// Em debug, a coleta fica desligada para não poluir o dashboard.
Future<void> configureCrashReporting() async {
  if (kIsWeb) return;

  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Reporta erro não fatal (ex.: falha de sync recuperável em release).
Future<void> recordNonFatalError(
  Object error,
  StackTrace stackTrace, {
  String? reason,
}) async {
  if (kIsWeb || kDebugMode) return;

  await FirebaseCrashlytics.instance.recordError(
    error,
    stackTrace,
    reason: reason,
    fatal: false,
  );
}

/// Reporta erros inesperados, ignorando falhas de rede comuns (offline/timeout).
Future<void> reportUnexpectedError(
  String reason,
  Object error,
  StackTrace stackTrace,
) async {
  if (error is SocketException || error is TimeoutException) return;
  await recordNonFatalError(error, stackTrace, reason: reason);
}
