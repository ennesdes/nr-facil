# Branding input

O Terminal **não consegue ler** `~/Downloads` no macOS (`Operation not permitted`) — nem com `sudo`.
Use o **Finder** para arrastar os arquivos para cá:

1. `logo.png` ← arraste **ChatGPT Image 5 de set. de 2026, 20_37_00.png** e renomeie para `logo.png`
2. `easyappicon-icons-1788651440281/` ← arraste a pasta inteira do EasyAppIcon

Depois rode na raiz do repo:

```bash
./scripts/import_branding.sh
```
