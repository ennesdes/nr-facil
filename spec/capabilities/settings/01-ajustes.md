# Ajustes

> **SSOT:** `SettingsPage`.

## Regras

| Condição | Então |
|----------|--------|
| Tema | system / light / dark via `ThemeController` → `StorageKeys.appThemeMode` |
| Atualizações de conteúdo | Texto informativo (sync automático quando online) — **sem** botão “Verificar atualizações” |
| Verificar atualizações manualmente | Tela do sino (Atualizações) → `syncMetadata` |
| Aviso legal / links | Acesso a textos oficiais e política de privacidade |
| Entrada | Ícone na app bar (aba Normas) |

Sem conta/login — app 100% offline-first para leitura.
