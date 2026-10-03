import 'package:nrfacil/core/services/analytics_service.dart';

/// Grava eventos/telas em memória em vez de enviar ao Firebase.
class FakeAnalyticsService extends AnalyticsService {
  final events = <(String, Map<String, Object>)>[];
  final screens = <String>[];

  @override
  Future<void> sendEvent(String name, Map<String, Object> parameters) async {
    events.add((name, parameters));
  }

  @override
  Future<void> sendScreen(String name) async {
    screens.add(name);
  }
}
