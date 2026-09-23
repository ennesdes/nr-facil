# Design — capturas de tela do app

Referências visuais do NR Fácil, organizadas por **feature** (não substituem Figma nem o [design system](../docs/design-system.md)).

| Pasta | Feature |
|-------|---------|
| [`home/normas/`](home/normas/) | Aba Normas (lista de NRs) |
| [`compliance/checklist/`](compliance/checklist/) | Checklist de conformidade / multas (NR-28) |

**Como atualizar (recomendado):**

```bash
maestro test .maestro/flows/design/compliance_checklist.yaml
./scripts/sync_maestro_design_screenshots.sh
```

Alternativa manual: `scripts/capture_compliance_checklist_design.sh` (requer emulador 1080×2400 e `flutter screenshot`).

Capturas de 22/09/2026 — build debug, tema claro do emulador.
