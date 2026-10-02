# Perfil da empresa

## Campos

Segmento/atividade (`segmentoId`), porte, fatores de risco (lista dinâmica do JSON).

## Regras

| Condição | Então |
|----------|--------|
| Primeiro acesso à aba Checklist | Formulário de cadastro |
| Perfil salvo | `StorageKeys.companyProfile` |
| Editar perfil | Atualiza checklist aplicável |

v1: um perfil por instalação.
