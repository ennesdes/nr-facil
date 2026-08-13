# NR Fácil

App Android para consulta offline às Normas Regulamentadoras (NRs) oficiais do MTE — com busca, favoritos e atualização automática.

## Começar

1. Abra o **[todo.md](todo.md)** — checklist do que fazer em ordem
2. Siga o próximo item `[ ]` não marcado
3. Procedures manuais: **[docs/procedures/](docs/procedures/)**
4. Prompts para o Cursor: **[docs/prompts.md](docs/prompts.md)**
5. Arquitetura técnica: **[docs/architecture.md](docs/architecture.md)**

## Setup rápido

```bash
# 1. FVM + dependências
./scripts/setup.sh

# 2. Verificar
fvm flutter doctor
./scripts/check.sh
```

Procedure detalhada: [docs/procedures/01-configurar-fvm.md](docs/procedures/01-configurar-fvm.md)

## Stack

- **Flutter** (FVM) — app Android
- **GitHub** — conteúdo versionado (fonte da verdade)
- **Supabase** — metadados leves (atualizações, versão mínima)
- **AdMob + IAP** — monetização

## Estrutura

```
app/        → Flutter
content/    → NRs em Markdown + assets
scripts/    → Pipeline Python + check.sh
docs/       → Procedures, prompts, arquitetura
```

## Licença / legal

Conteúdo das NRs: domínio público (MTE). Código do app: a definir.

O app não substitui a consulta às publicações oficiais no portal gov.br.
