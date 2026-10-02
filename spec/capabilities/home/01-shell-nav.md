# Home — shell e navegação

> **SSOT:** `HomePage` e `HomeController` — abas e app bar.

## Escopo

Shell principal após abrir o app; quatro abas na bottom nav.

## Regras

| Condição | Então |
|----------|--------|
| Abertura do app | `home: HomePage` no `GetMaterialApp` |
| Bottom nav | **Normas** · **Favoritos** · **Buscar** · **Checklist** |
| Aba padrão | Favoritos se ≥1 favorito; senão Normas |
| App bar | Título da aba · sino (só Normas) · ajustes (Normas) · ações do Checklist quando ativo |
| Histórico de leitura | Automático — **não** é aba |

## Checklist (entrada)

| Condição | Então |
|----------|--------|
| Aba Checklist sem perfil salvo | Fluxo de cadastro de empresa |
| Com perfil salvo | Checklist consolidado direto |

Ver [`../compliance/02-checklist.md`](../compliance/02-checklist.md).
