import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Configura Firebase Performance Monitoring.
///
/// Só deve ser chamado após [Firebase.initializeApp] ter sucesso.
/// Em debug, a coleta fica desligada para não poluir o dashboard.
Future<void> configurePerformanceMonitoring() async {
  if (kIsWeb) return;

  await FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode);
}

/// Executa [action] dentro de um custom trace (release apenas).
Future<T> runPerformanceTrace<T>(
  String traceName,
  Future<T> Function() action, {
  Map<String, String>? attributes,
}) async {
  if (kIsWeb || kDebugMode) return action();

  final trace = FirebasePerformance.instance.newTrace(traceName);
  if (attributes != null) {
    for (final entry in attributes.entries) {
      trace.putAttribute(entry.key, entry.value);
    }
  }

  await trace.start();
  try {
    return await action();
  } finally {
    await trace.stop();
  }
}
