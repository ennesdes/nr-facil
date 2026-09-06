# CI/CD — Deploy na Play Store

O workflow roda em **7 jobs** visíveis no GitHub Actions:

1. **Validar secrets** — Play Console + keystore + AdMob (8 secrets)
2. **Format · Fix** — `dart fix` + `dart format`
3. **Analyze** — `flutter analyze --fatal-infos`
4. **Testes** — `flutter test`
5. **Assinar · Build AAB** — version bump, keystore, AdMob via secrets, build release
6. **Publicar Play Store** — upload no track escolhido (`internal` / `production`)
7. **Version bump** — commita `app/pubspec.yaml` após publish ok

Disparo: **Actions → Deploy Play Store → Run workflow** (`workflow_dispatch`).

Nenhum secret vai para o git — keystore, Service Account e IDs AdMob de produção existem só nos GitHub Secrets.

---

## GitHub Secrets obrigatórios (8)

Cadastrar em **Settings → Secrets and variables → Actions** do repositório `ennesdes/nr-facil`:

### Play Console + assinatura (5)

| Secret | Origem | Usado em |
|--------|--------|----------|
| `PLAY_SERVICE_ACCOUNT_JSON` | Chave JSON da Service Account (Google Cloud) | Upload para Play Console |
| `ANDROID_KEYSTORE_BASE64` | Keystore local codificado em base64 | Assinatura do AAB |
| `KEYSTORE_PASSWORD` | `app/android/key.properties` → `storePassword` | Assinatura do AAB |
| `KEY_ALIAS` | `app/android/key.properties` → `keyAlias` | Assinatura do AAB |
| `KEY_PASSWORD` | `app/android/key.properties` → `keyPassword` | Assinatura do AAB |

> Se você já usa Agenda Fácil ou Treino Base na mesma conta Google, pode **reutilizar a mesma Service Account** (`PLAY_SERVICE_ACCOUNT_JSON`) — só precisa convidar a SA no app **NR Fácil** no Play Console.

### AdMob (3) — não commitar no repo público

| Secret | Origem | Usado em |
|--------|--------|----------|
| `ADMOB_APP_ID` | AdMob → App → App ID (`ca-app-pub-…~…`) | `AndroidManifest` (via env no build Gradle) |
| `ADMOB_BANNER_UNIT_ID` | AdMob → unidade Banner | `--dart-define` no build Flutter |
| `ADMOB_INTERSTITIAL_UNIT_ID` | AdMob → unidade Interstitial | `--dart-define` no build Flutter |

Ver [05-configurar-admob.md](procedures/05-configurar-admob.md) para criar app e unidades no AdMob.

---

## Passo a passo — keystore

1. Gere o keystore seguindo [06-gerar-keystore.md](procedures/06-gerar-keystore.md)
2. Crie `app/android/key.properties` (já está no `.gitignore`):

```properties
storePassword=SUA_SENHA
keyPassword=SUA_SENHA
keyAlias=upload
storeFile=upload-keystore.jks
```

3. Coloque `upload-keystore.jks` em `app/android/app/`
4. Cadastre os 4 secrets de keystore no GitHub:

```bash
# Na raiz do repo, com o keystore em app/android/app/upload-keystore.jks
base64 -i app/android/app/upload-keystore.jks | pbcopy   # macOS
```

| Secret | Valor |
|--------|-------|
| `KEYSTORE_PASSWORD` | `storePassword` do key.properties |
| `KEY_ALIAS` | `keyAlias` (ex.: `upload`) |
| `KEY_PASSWORD` | `keyPassword` |
| `ANDROID_KEYSTORE_BASE64` | saída do base64 acima |

---

## Passo a passo — Service Account (Play Console)

Se já configurou no Treino Base ou Agenda Fácil, pule para o item 2.

### 1. Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services → Enable APIs** → **Google Play Android Developer API**
3. **IAM → Service Accounts → Create** (ex.: `github-actions-play-deploy`)
4. **Keys → Add Key → JSON** → baixe o arquivo
5. Cole o JSON inteiro no secret `PLAY_SERVICE_ACCOUNT_JSON`

### 2. Play Console — app NR Fácil

1. [Play Console](https://play.google.com/console/) → **Users and permissions**
2. Convide o e-mail da Service Account (`...@....iam.gserviceaccount.com`)
3. Permissão: **Release manager**
4. Crie o app **NR Fácil** com package `com.douglasennes.nrfacil` (se ainda não existir)

---

## Passo a passo — AdMob secrets

1. [admob.google.com](https://admob.google.com/) → app **NR Fácil** (Android)
2. Copie o **App ID** → secret `ADMOB_APP_ID`
3. Crie unidade **Banner** (`banner_home`) → secret `ADMOB_BANNER_UNIT_ID`
4. Crie unidade **Interstitial** (`interstitial_reader_exit`) → secret `ADMOB_INTERSTITIAL_UNIT_ID`

O repositório público mantém apenas IDs de **teste** do Google. Os IDs reais entram só no build de release via secrets.

---

## Build local de release (opcional)

Sem commitar IDs reais:

```bash
cp app/admob.local.env.example app/admob.local.env
# Edite app/admob.local.env com seus IDs reais

set -a && source app/admob.local.env && set +a
export ADMOB_APP_ID   # Gradle lê para o AndroidManifest

cd app
fvm flutter build appbundle --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --dart-define=ADMOB_BANNER_UNIT_ID="$ADMOB_BANNER_UNIT_ID" \
  --dart-define=ADMOB_INTERSTITIAL_UNIT_ID="$ADMOB_INTERSTITIAL_UNIT_ID"
```

AAB: `app/build/app/outputs/bundle/release/app-release.aab`

**Ofuscação:** o CI e o comando acima usam `--obfuscate` (Dart) + R8 (`minifyEnabled` no Gradle). Isso dificulta engenharia reversa, mas **não esconde** IDs AdMob nem outras strings necessárias em runtime.

**Símbolos:** guarde `build/app/outputs/symbols/` localmente (ou baixe o artefato `app-release-symbols` do job de build no GitHub Actions) para desofuscar stack traces de crash com `flutter symbolize`.

---

## Permissões do repositório

**Settings → Actions → General → Workflow permissions** = **Read and write permissions**

Necessário para cache, commits automáticos de format e version bump.

---

## Como disparar o deploy

1. Confirme os **8 secrets** cadastrados
2. GitHub → **Actions** → **Deploy Play Store** → **Run workflow**
3. Branch: `main`
4. Track: `internal` (primeiro deploy) ou `production`
5. Acompanhe o **Job Summary** de cada job

---

## Checklist antes do primeiro deploy

- [ ] App criado no Play Console (`com.douglasennes.nrfacil`)
- [ ] Service Account com Release manager no app NR Fácil
- [ ] `PLAY_SERVICE_ACCOUNT_JSON` cadastrado
- [ ] Keystore gerado + 4 secrets de assinatura
- [ ] App + unidades criadas no AdMob + 3 secrets AdMob
- [ ] Política de privacidade publicada ([08-github-pages-privacidade.md](procedures/08-github-pages-privacidade.md))
- [ ] Workflow permissions = Read and write
- [ ] Primeiro deploy no track `internal`

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `Missing required secret(s): ADMOB_*` | Cadastre os 3 secrets AdMob no GitHub |
| `versionCode` duplicado | Workflow incrementa automaticamente; confira se o bump foi commitado |
| Ad não carrega em teste interno | Aguarde até 24h após criar unidade; use dispositivo de teste no AdMob |
| Push do bot rejeitado | Branch protegida — libere push para `github-actions[bot]` |

---

## Referências

- [05-configurar-admob.md](procedures/05-configurar-admob.md)
- [06-gerar-keystore.md](procedures/06-gerar-keystore.md)
- [07-publicar-play-store.md](procedures/07-publicar-play-store.md)
