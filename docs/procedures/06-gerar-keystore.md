# Procedure 06 — Gerar keystore Android

## Objetivo

Criar keystore para assinar o APK/AAB de release da Play Store.

## Pré-requisitos

- Java JDK instalado (`keytool` no PATH)
- Senhas fortes anotadas em gerenciador de senhas

## ⚠️ Crítico

- **Nunca** commite o `.jks` ou senhas no git
- **Perder o keystore = não atualizar o app** na Play Store
- Faça backup em local seguro (1Password, USB criptografado, etc.)

## Passo a passo

### 1. Criar pasta fora do repo (recomendado)

```bash
mkdir -p ~/secrets/nr-facil
cd ~/secrets/nr-facil
```

### 2. Gerar keystore

```bash
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Preencha quando pedido:

- Senha do keystore (guarde!)
- Nome, organização, cidade, estado, país (BR)

### 3. Criar `key.properties` (fora do repo ou em app/android/)

Em `app/android/key.properties` (já no `.gitignore`):

```properties
storePassword=SUA_SENHA_KEYSTORE
keyPassword=SUA_SENHA_KEY
keyAlias=upload
storeFile=/Users/SEU_USUARIO/secrets/nr-facil/upload-keystore.jks
```

Use caminho **absoluto** para `storeFile`.

### 4. Configurar build.gradle

Peça ao Cursor (prompt I10) ou configure manualmente em `app/android/app/build.gradle` a leitura de `key.properties` para `signingConfigs.release`.

### 5. Backup

Copie `upload-keystore.jks` para:

- [ ] Gerenciador de senhas (anexo)
- [ ] Backup em nuvem criptografada
- [ ] Anotar: alias, senhas, validade

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `keytool: command not found` | Instale JDK: `brew install openjdk` |
| Build falha "keystore not found" | Verifique caminho absoluto em `storeFile` |
| Esqueci a senha | Não há recuperação — novo app na Play Store |

## Próximo passo

→ Item 36 do [todo.md](../../todo.md) — `fvm flutter build appbundle`
