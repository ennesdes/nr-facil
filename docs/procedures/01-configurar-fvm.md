# Procedure 01 — Configurar FVM

## Objetivo

Fixar a versão do Flutter no projeto e usar `fvm flutter` em vez do Flutter global.

## Pré-requisitos

- [Dart SDK](https://dart.dev/get-dart) instalado (vem com Flutter global ou standalone)
- Terminal (macOS: Terminal ou iTerm)

## Passo a passo

### 1. Instalar FVM

```bash
dart pub global activate fvm
```

Se `fvm` não for encontrado, adicione ao PATH (geralmente `~/.pub-cache/bin`):

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
# Adicione essa linha ao ~/.zshrc para persistir
```

### 2. Entrar no projeto

```bash
cd /caminho/para/nr-facil
```

### 3. Instalar a versão fixada

O arquivo `.fvmrc` na raiz já define a versão (`3.24.0`):

```bash
fvm install
fvm use
```

### 4. Verificar

```bash
fvm flutter doctor -v
```

Corrija o que aparecer em vermelho (Android SDK, licenças, etc.).

### 5. Rodar setup do projeto

```bash
chmod +x scripts/setup.sh scripts/check.sh
./scripts/setup.sh
```

### 6. Cursor / VS Code

O arquivo `.vscode/settings.json` já aponta para `.fvm/flutter_sdk`.  
Reabra o Cursor após `fvm use`.

## Comandos do dia a dia

Sempre use `fvm flutter` em vez de `flutter`:

```bash
fvm flutter run
fvm flutter pub get
fvm flutter analyze
fvm flutter build appbundle
```

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `fvm: command not found` | Adicione `~/.pub-cache/bin` ao PATH |
| `Flutter SDK not found` | Rode `fvm install` e `fvm use` na raiz |
| Cursor não reconhece SDK | Reabra o editor; confira `.vscode/settings.json` |
| Versão diferente no CI | Use a mesma versão do `.fvmrc` na GitHub Action |

## Próximo passo

→ [todo.md](../../todo.md) item 02 — Criar monorepo / projeto Flutter
