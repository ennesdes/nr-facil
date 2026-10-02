# Sincronização remota (sem backend)

> **SSOT:** como o app obtém índice e feed — só GitHub raw HTTP.

## Fontes

| Recurso | URL | Escrito por |
|---------|-----|-------------|
| `manifest.json` | GitHub raw | Action `update-nrs.yml` |
| `app_meta.json` | GitHub raw | `build_app_meta.py` na Action |
| Conteúdo por NR | paths no manifest | pipeline Python |

## Regras

| Condição | Então |
|----------|--------|
| App em runtime | **Nunca** chama portal MTE para baixar PDF/MD |
| Sem rede | Usar cache local (`path_provider`) |
| `min_app_version` em `app_meta.json` > versão instalada | Diálogo de update obrigatório no startup |
| Botão "Verificar atualizações" | `ContentService` refetch manifest + sync incremental |

## Implementação

- Serviço principal: `app/lib/core/services/content_service.dart`
- Config de URLs: `app/lib/core/constants/app_config.dart`
