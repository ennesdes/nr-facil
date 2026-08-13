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
3. Nome: `banner_lista_nrs`
4. Copie o **Ad unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ`

### 5. IDs de teste (desenvolvimento)

Use IDs oficiais de teste do Google durante dev — **nunca clique em seus próprios ads**:

- App ID teste: `ca-app-pub-3940256099942544~3347511713`
- Banner teste: `ca-app-pub-3940256099942544/6300978111`

### 6. Onde exibir no app

| Tela | Banner? |
|------|---------|
| Aba Favoritos | Sim |
| Aba Todos | Sim |
| Busca | Sim |
| Leitor de NR | **Não** |

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Ad não carrega | Use IDs de teste; confira internet; aguarde 24h após criar unidade |
| Conta AdMob suspensa | Não clique nos próprios anúncios; use dispositivos de teste |
| Política rejeitada | Conteúdo público MTE é ok; tenha privacy policy publicada |

## Próximo passo

→ Item 33 do [todo.md](../../todo.md) — integrar no Flutter
