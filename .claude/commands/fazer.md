Implemente a feature ou fix descrito em $ARGUMENTS.

> **Filosofia:** itens do `todo.md` são enxutos — estratégia e direção, poucos detalhes.
> Na execução, **pensar criticamente** em **conteúdo/pipeline + tela + lacunas** antes de codar.

---

## 0. Contexto e pensamento crítico (obrigatório)

> **Se invocado via `/fazer` com plano:** ler `.claude/plans/<slug>.md` primeiro — usar como roteiro; não re-pesquisar o que o plano já cobre.

1. Ler `CLAUDE.md`
2. Localizar item correspondente em `todo.md` (se existir) — entender **intenção**, não só o texto
3. Se o item tiver um prompt correspondente em `docs/prompts.md` (I0–I10) → ler antes de definir escopo
4. Ler `docs/architecture.md` nas seções relevantes ao escopo

### A. Conteúdo e pipeline (sempre pensar — implementar se aplicável)

Se a tarefa toca `scripts/` ou `content/`:
- Qual princípio de `docs/architecture.md` § Pipeline de conteúdo se aplica (nunca reescrever texto normativo, 3 passes uniformes, isolamento de erro por NR)?
- A mudança altera como o `pdf_hash` é calculado ou como updates são detectados?
- Edge cases: NR revogada, scraping fora do padrão, PDF corrompido, override em `nr_sources.json`

Regra nova ou ambígua → considerar acionar `python-pipeline` (implementação) ou `tech-lead` (decisão de custo/arquitetura) — ou validar inline com fundamento em `docs/architecture.md`.

### B. Telas e experiência (sempre pensar — implementar se aplicável)

Se a tarefa toca `app/`, mesmo em tarefa de service o usuário vê o **resultado** — definir:
- Estados: loading/erro/vazio/sucesso
- Onde aparece na navegação (Favoritos/Todos/leitor/sino)
- Ads nunca no leitor; link PDF oficial + aviso legal sempre presentes no leitor

### C. Lacunas da tarefa

Listar o que o `todo.md`/prompt **não especificou** e precisa ser decidido agora:
- Fluxo do usuário — de onde vem, para onde vai
- Contratos entre camadas — service ↔ controller ↔ widget (app) ou script ↔ script (pipeline)
- Testes mínimos — caminho feliz + falha + edge case

Se ambiguidade **bloqueia** e tem trade-off real → perguntar ao usuário (`AskUserQuestion`) antes de codar, em vez de assumir.

Apresentar brevemente (5–12 linhas): decisões de **conteúdo/pipeline** + **tela** + **técnico**.

---

## 1. Implementar

Acionar o agente conforme o escopo:
- **`flutter-senior`** — UI/Dart/GetX/widgets/services em `app/`
- **`python-pipeline`** — scraping, extração de PDF, manifest/índices em `scripts/`
- **`tech-lead`** — Supabase (schema/RLS), GitHub Actions, arquitetura, custo, monetização

Usar em paralelo quando a feature cruzar camadas (ex.: novo campo no manifest → `python-pipeline` gera + `flutter-senior` consome).

Não entregar só metade — se a tarefa impacta o que o usuário vê, não parar só no service/script sem a tela/consumo correspondente.

> **Atenção:** não fazer `git commit` por iniciativa própria — só commitar se o usuário pedir explicitamente.

---

## 2. Verificar

- `./scripts/check.sh` (analyze + test + validate_manifest) se tocou `app/` ou `manifest.json`
- Remover imports/código obsoleto gerado pela mudança
- Se item do `todo.md` → marcar `[x]`
- Se criou/moveu script ou mudou schema do manifest → atualizar `docs/architecture.md` e `scripts/README.md`

---

## 3. Próximo passo

- Fix pontual (≤ 3 arquivos, sem plano) → **`/revisar`** antes de commitar.
- Plano com múltiplas fases concluído → commitar a fase atual antes de seguir para a próxima (evita diff gigante).
- Diff grande (> 500 linhas) → sugerir dividir em commits por fase antes de continuar.
