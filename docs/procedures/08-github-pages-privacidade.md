# Procedure 08 — Política de privacidade e termos (Solve Better)

## Objetivo

Usar URLs públicas exigidas pela Play Store e AdMob para privacidade e termos do NR Fácil.

## URLs oficiais (fonte da verdade)

| Documento | URL |
|-----------|-----|
| Política de privacidade | https://solvebetter.com.br/apps/nr-facil/privacidade/ |
| Termos de uso | https://solvebetter.com.br/apps/nr-facil/termos/ |
| Site do app | https://solvebetter.com.br/apps/nr-facil/ |

Conteúdo mantido no repositório **`site-solve-better`** (`src/pages/apps/nr-facil/`). Deploy automático na Vercel → `solvebetter.com.br`.

## Onde usar

| Onde | Campo / ação |
|------|----------------|
| Play Console | Política do app → **Política de privacidade** → URL de privacidade acima |
| Play Console | Presença na loja → **Website** → `https://solvebetter.com.br` (para `app-ads.txt` em `/app-ads.txt`) |
| AdMob | Configurações do app (se solicitado) |
| App Flutter | `AppConfig.privacyPolicyUrl` e `AppConfig.termsOfUseUrl` — Ajustes → Legal |

## app-ads.txt

Com website `https://solvebetter.com.br` na Play Console, publique em:

```
https://solvebetter.com.br/app-ads.txt
```

Arquivo: `site-solve-better/public/app-ads.txt`. Ver [05-configurar-admob.md](05-configurar-admob.md#9-app-adstxt-verificação-iab).

## Rascunho local (opcional)

`docs/privacy-policy.md` neste repo é rascunho/referência — **não** é a URL usada na loja. A versão publicada é a do site Solve Better.

## Troubleshooting

| Problema | Solução |
|----------|---------|
| 404 na URL | Confira deploy do `site-solve-better` na Vercel |
| Play rejeita URL | Deve ser HTTPS pública; teste no navegador anônimo |
| App abre link errado | Confira `AppConfig` e faça rebuild |

## Próximo passo

→ Item 38 do [todo.md](../../todo.md)
