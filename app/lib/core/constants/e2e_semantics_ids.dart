/// Barrel que reexporta todas as classes de Semantic IDs para testes E2E com Maestro.
///
/// **Convenção:** Cada tela/feature tem uma classe `XxxSemanticsIds` em `semantics/xxx_semantics_ids.dart`
/// com constantes `static const String xxx = 'literal'`. Os mesmos literais devem ser usados no YAML
/// do Maestro: `Semantics(identifier: XxxSemanticsIds.foo)` em Dart ↔ `id: 'foo'` no YAML.
///
/// **Gate automático:** `scripts/check_e2e_semantics.py` valida que todos os `id:` usados em
/// `.maestro/flows/**/*.yaml` e `.maestro/subflows/**/*.yaml` têm um correspondente em constantes
/// Dart definidas aqui. Falha no commit se houver id órfão.
library;

export 'semantics/home_semantics_ids.dart';
export 'semantics/reader_semantics_ids.dart';
export 'semantics/management_semantics_ids.dart';
