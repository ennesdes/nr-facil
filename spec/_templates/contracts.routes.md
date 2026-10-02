# Fragmento — navegação GetX

| Nome / destino | Página | Binding | `Get.arguments` | Voltar |
|----------------|--------|---------|-----------------|--------|
| `home` | `HomePage` | `AppBinding` | — | — |
| leitor | `NrReaderPage` | `ReaderBinding` | `nrId`, anchor opcional | `Get.back` |

- App usa `home: HomePage` no `GetMaterialApp`; leitor e telas auxiliares via `Get.to` / helpers em `ReaderNavigation`.
- Alterou binding que lê arguments → cobrir em teste de navegação.
