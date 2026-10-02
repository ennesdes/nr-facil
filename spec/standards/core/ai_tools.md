# Ferramentas de IA no desenvolvimento

## Flutter (`app/`)

- Dart MCP (`user-dart`): analyze, hot reload após mudanças
- Marionette (`user-marionette`): E2E em debug — conectar ao VM service do `flutter run`

## Revisão

- `/revisar`: preferir diff local + `flutter-reviewer`; evitar MCPs que alterem estado do app durante revisão estática

## Pipeline

- Executar scripts Python reais — não editar `manifest.json` / `content/` gerados à mão
