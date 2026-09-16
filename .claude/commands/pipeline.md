Rode o gate de qualidade local do NR Fácil, corrija o que precisar e me dê um resumo enxuto.

> **Objetivo:** substituir o ciclo "push → Action falha → corrigir → push de novo" por um check local que já corrige e reporta antes do commit.

---

## Passos

1. Execute `./scripts/precommit.sh` a partir da raiz do repo.
2. Analise a saída:
   - **Auto-fixes do próprio script** (dart format, seed manifest): só confirme no resumo, não precisa re-explicar.
   - **Falhas reais** (flutter analyze, flutter test, validate_manifest.py, validate_quality.py, audit_contrast.py): identifique a causa raiz de cada uma e corrija o código/teste/conteúdo — nunca desative uma checagem ou pule com `--no-verify`/flags para "passar por cima" do erro.
   - Se uma falha exigir uma decisão de produto/arquitetura com trade-off real (não um bug óbvio), pare e pergunte ao usuário em vez de decidir sozinho.
3. Depois de corrigir, rode `./scripts/precommit.sh` de novo para confirmar que ficou tudo verde.
4. Rode `git status --short` e confira que as alterações fazem sentido (nada gerado sendo commitado à toa, nada sensível).

## Saída esperada

Resposta curta (poucas linhas), em português, no formato:
- ✅ **Tudo OK** — nada a corrigir, pode commitar. *(se não houve nenhum problema)*
- ou uma lista enxuta do que foi corrigido, arquivo por arquivo, com uma frase da causa — sem novela.

Não crie documentos, não repita o log inteiro do script, não peça permissão para rodar `./scripts/precommit.sh` de novo depois de uma correção.
