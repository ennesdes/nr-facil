# Validação de UI/UX — NR Fácil

> Execute ao implementar tela/widget **antes** de declarar pronto. Tokens: `spec/standards/ui/design_system.md`.

## Filtro de elemento (5 perguntas)

1. Por que este elemento existe nesta tela? (uma frase)
2. Usuário SST leigo entende e sabe o próximo passo?
3. Informação densa está abaixo do fold ou em sheet — não bloqueia ação principal?
4. Hierarquia: uma ação principal por tela (ler, baixar, buscar)?
5. Momento certo? (ex.: disclaimer no leitor, não na lista)

## Checklist estética

- [ ] Sem hex/dp hardcoded — `AppColors`, `AppSpacing`, `AppTypography`
- [ ] Contraste WCAG AA (rodar `scripts/audit_contrast.py` se mudou cores)
- [ ] Shimmer do layout real em loading de listas
- [ ] Estado vazio com CTA (baixar NR, ajustar busca, cadastrar perfil)
- [ ] Tema claro/escuro legível

## Checklist usabilidade

- [ ] Toque ≥ 48dp em ícones e chips
- [ ] Offline: mensagem clara (`user_messages.dart`)
- [ ] Leitor: scroll e fonte ajustável sem perder contexto
- [ ] Ads só em listas — **nunca** no leitor
- [ ] NR revogada: visual distinto + sem leitor interno enganoso

## Acessibilidade

- [ ] `Semantics` / ids E2E em fluxos críticos (`.maestro/flows/ci/`)
- [ ] Labels em botões só-ícone (sino, ajustes)

## Julgamento sênior (prosa)

A tela responde em 3s o que o usuário precisa fazer? O disclaimer legal está visível onde a norma é lida?
