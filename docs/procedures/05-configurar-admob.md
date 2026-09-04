# Procedure 05 — Configurar AdMob

## Objetivo

Criar app no AdMob e obter IDs para banners no NR Fácil.

## Pré-requisitos

- Conta Google (mesma do Play Console ajuda)
- App criado no Play Console (pode ser rascunho)

## Passo a passo

### 1. Criar conta AdMob

1. https://admob.google.com/
2. Login com conta Google
3. Aceite termos

### 2. Adicionar app

1. **Apps → Adicionar app**
2. O app já está publicado? → **Não** (durante desenvolvimento)
3. Plataforma: **Android**
4. Nome: **NR Fácil**
5. Confirme

### 3. Obter App ID

Formato: `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`

Guarde para `app/android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

### 4. Criar unidade de anúncio (Banner)

1. No app → **Unidades de anúncio → Adicionar**
2. Formato: **Banner**
3. Nome: `banner_home`
4. Copie o **Ad unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`

### 5. Criar unidade de anúncio (Interstitial)

1. No app → **Unidades de anúncio → Adicionar**
2. Formato: **Interstitial**
3. Nome: `interstitial_reader_exit`
4. Copie o **Ad unit ID** para `AppConfig.admobInterstitialUnitId`

### 6. IDs de teste (desenvolvimento)

Use IDs oficiais de teste do Google durante dev — **nunca clique em seus próprios ads**:

- App ID teste: `ca-app-pub-3940256099942544~3347511713`
- Banner teste: `ca-app-pub-3940256099942544/6300978111`
- Interstitial teste: `ca-app-pub-3940256099942544/1033173712`

### 7. Onde exibir no app

| Tela | Banner fixo | Interstitial |
|------|-------------|--------------|
| Home (Normas / Favoritos / Buscar) | Sim (acima da bottom nav) | Ao voltar do leitor* |
| Leitor de NR | **Não** | **Não** |
| Ajustes / Atualizações | **Não** | **Não** |

\* Interstitial só se passaram ≥15 min desde o último, sessão ≥2 min, e usuário já abriu o leitor nesta sessão.

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Ad não carrega | Use IDs de teste; confira internet; aguarde 24h após criar unidade |
| Conta AdMob suspensa | Não clique nos próprios anúncios; use dispositivos de teste |
| Política rejeitada | Conteúdo público MTE é ok; tenha privacy policy publicada |

## Próximo passo

→ Item 33 do [todo.md](../../todo.md) — integrar no Flutter
