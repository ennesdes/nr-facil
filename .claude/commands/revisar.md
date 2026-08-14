# /revisar

Portão de qualidade final antes de commitar — **diff** por padrão, ou **pasta(s)** específicas quando indicado em `$ARGUMENTS`.

**Objetivo:** decidir se pode commitar. Resposta curta — sem narrar o diff/arquivos, sem repetir o que o script já disse.

---

## 1. Rodar a parte mecânica

**Sem `$ARGUMENTS`:**

```bash
git status --short
git diff main...HEAD --stat 2>/dev/null || git diff --stat
```

Se não houver nada para revisar (working tree limpa e sem diff contra `main`), informe e **encerre** — não acione agentes.

Depois, rodar:

```bash
./scripts/check.sh
```

Isso cobre `flutter analyze --fatal-infos` + `flutter test` + `validate_manifest.py` — não repita esses comandos separadamente depois.

**Com `$ARGUMENTS`** (audita pasta/arquivo específico, fora do fluxo normal de commit):
1. `git diff main...HEAD -- <caminho1> <caminho2> ...` (+ unstaged para os mesmos caminhos)
2. Diff não vazio → modo diff, restrito a esses caminhos
3. Diff vazio (já commitado) → modo pasta: ler os arquivos de cada pasta via `Glob`/`Read` como auditoria completa

---

## 2. Gate por tamanho do diff

| Linhas alteradas | Comportamento |
|-------------------|----------------|
| ≤ 200 | Aciona `flutter-reviewer`; se ✅, pode omitir Opcional |
| 200–500 | Aciona `flutter-reviewer`; Opcional só se houver Fazer/Não fazer |
| 500–1000 | Aciona `flutter-reviewer`; máx. **3** itens em Fazer; **sem** Opcional — melhorias não bloqueantes vão em **Depois** (máx. 2) |
| > 1000 | **Não** acionar o agente — `check.sh` já basta; máx. **2** Fazer (bug/regressão/regra inviolável); recomendar **commit agora** e follow-up |

---

## Anti-loop (obrigatório)

Objetivo: encerrar o ciclo `fazer → revisar → corrigir → revisar` no mesmo diff.

| Situação | Comportamento |
|----------|----------------|
| Usuário pede **`corrigir`** após `/revisar` | Implementar **só** itens de **Fazer** — ignorar Opcional salvo pedido explícito |
| Após **`corrigir`** dos Fazer | Responder **"Pronto para commit"** — **não** sugerir `/revisar` de novo |
| **≥ 2** `/revisar` no **mesmo diff** sem commit | Gate de > 1000 linhas automático: máx. 2 Fazer restantes ou **✅ Pode commitar (ciclo encerrado)** se `check.sh` passar |
| Usuário diz **"commit"** ou **"pode commitar"** | Parar revisões; ajudar no commit, não rodar `/revisar` |
| Dúvida pontual resolvível com 1 comando/leitura | Resolver direto — **não** rechamar `flutter-reviewer` só pra confirmar |

---

## 3. Acionar o agente (só se o gate permitir)

Um agente só: `flutter-reviewer`. Ele cobre sozinho bugs, arquitetura, performance, segurança, duplicação, fidelidade de conteúdo e UI/UX — não acionar `qa-engineer`/`tech-lead`/`python-pipeline` neste fluxo (revisão de teste/arquitetura de fundo é outro momento, não o gate de commit).

1. **Sempre** passar ao `flutter-reviewer` o diff literal e instruir explicitamente: *"use exatamente este diff — não rode `git diff` por conta própria; analyze/test/validate_manifest já foram checados, não rode de novo"*. Em modo pasta, instruir a ler os arquivos completos (não há diff).
2. Diff > 1000 linhas → **não acionar o agente** — o `check.sh` já basta (ver §2).
3. Se o agente retornar a seção **Dúvidas**, repassar como está — não tentar resolver nem acionar outro agente para tirá-la.

---

## 4. Resposta (formato fixo)

```
## Status
✅ Pode commitar | ⚠️ Ajustes necessários | ❌ Não commitar

## Fazer
- [problema → ação]

## Evitar
- [anti-padrão → parar de repetir este erro daqui pra frente]

## Depois
- [melhoria real que não bloqueia o commit → ação]

## Opcional
- [nice-to-have → ação]

## Dúvidas
- [o que muda → por que está em dúvida]
```

Regras:
- **1 linha por item** — problema → ação. Sem elogios, sem descrever o diff.
- Seção vazia → `- —` — **exceto** `Dúvidas`: omitir a seção inteira se o agente não relatou nenhuma
- **Fazer** = bloqueia commit (bug, regressão, violação de regra inviolável, `check.sh` com falha, refactor obrigatório para entregar a feature)
- **Evitar** = somente anti-padrões comportamentais a não repetir. **Nunca** refactors/extrações/"fazer depois" aqui
- **Depois** = trabalho real que não bloqueia o commit
- **Opcional** = nice-to-have que não bloqueia
- **Dúvidas** = não bloqueia — repassar como o agente reportou
- Status segue o pior item de **Fazer**
- `todo.md`/docs desatualizados entram em **Fazer**

**Diff pequeno e limpo → colapsar tudo em uma linha**, sem nenhuma seção:

```
Tudo certo. Pode commitar.
```

Usar sempre que `check.sh` passar e o `flutter-reviewer` não retornar item de **Fazer** — independente do tamanho do diff.

**Diff > 500 linhas → nunca gerar seção Opcional** — usar **Depois** para melhorias reais não bloqueantes.

**Instruir o `flutter-reviewer`:** usar **Evitar** só para anti-padrões; refactors/extrações → **Depois** ou **Opcional**; nunca rotular trabalho real como "Não fazer".

**Exemplos**

❌ `Foi identificado que o ContentService pode causar downloads redundantes...`
✅ `ContentService baixa NR mesmo com hash igual → comparar hash antes de fetch`

❌ `A implementação poderia evitar duplicação...`
✅ `Duplicação de parsing de manifest em 2 services → centralizar em ManifestParser`
