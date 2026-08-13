# Procedure 08 — GitHub Pages (privacidade)

## Objetivo

Publicar política de privacidade em URL pública exigida pela Play Store e AdMob.

## Pré-requisitos

- Repositório `nr-facil` no GitHub
- Arquivo `docs/privacy-policy.md` no projeto

## Passo a passo

### 1. Revisar conteúdo

Edite `docs/privacy-policy.md` se necessário:

- App usa conteúdo público do MTE
- Favoritos armazenados localmente
- AdMob (política Google)
- Supabase (metadados leves, sem dados pessoais sensíveis)
- Contato: seu e-mail

### 2. Habilitar GitHub Pages

1. GitHub → repositório **nr-facil**
2. **Settings → Pages**
3. **Source**: Deploy from a branch
4. Branch: `main` (ou `gh-pages`)
5. Folder: `/docs` ou configure workflow para publicar `docs/privacy-policy.md`

### Opção simples: arquivo `docs/index.html`

Crie `docs/index.html` que renderiza a política, ou use apenas o markdown com Jekyll (GitHub Pages suporta):

1. Adicione `docs/_config.yml`:
   ```yaml
   title: NR Fácil
   theme: jekyll-theme-minimal
   ```
2. Renomeie ou copie política para `docs/index.md` com front matter:
   ```markdown
   ---
   layout: default
   title: Política de Privacidade
   ---
   ```

### 3. Aguardar deploy

Após push, URL será algo como:

```
https://SEU_USUARIO.github.io/nr-facil/
```

ou

```
https://SEU_USUARIO.github.io/nr-facil/privacy-policy
```

### 4. Usar na Play Console

Cole a URL em:

- Play Console → Política do app → Política de privacidade
- AdMob → Configurações do app (se solicitado)

### 5. Link no app

Em Ajustes → "Política de privacidade" → abre URL no navegador.

## Troubleshooting

| Problema | Solução |
|----------|---------|
| 404 na URL | Aguarde 5–10 min; confira branch/folder em Settings → Pages |
| Página sem estilo | Normal para MD simples; conteúdo importa mais que visual |
| URL mudou | Atualize Play Console e AdMob |

## Próximo passo

→ Item 38 do [todo.md](../../todo.md)
