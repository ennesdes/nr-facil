# Assets da Play Store

Arquivos para upload na Play Console (item 37 do [todo.md](../todo.md)).

## Arquivos

| Arquivo | Dimensão | Uso |
|---------|----------|-----|
| `play_store_icon_512.png` | 512×512 | Presença na loja → Ícone do app |
| `feature_graphic_1024x500.png` | 1024×500 | Presença na loja → Gráfico de recursos |

Fontes em `app/assets/branding/` (`app_icon.png`, `app_icon_foreground.png`, `splash_mark.png`).

## Regenerar

### Feature graphic (capa)

Salve o arquivo como `~/Downloads/capa.png` (ou `.jpg` / `.jpeg` / `.webp`), depois:

```bash
source .venv/bin/activate
python3 scripts/import_feature_graphic.py
```

O script redimensiona/corta para `docs/store/feature_graphic_1024x500.png` (1024×500).

### Ícone + splash (Android e iOS)

Coloque em `branding-input/` via **Finder** (arrastar do Downloads — o Terminal não tem permissão):

- `logo.png` ← **ChatGPT Image 5 de set. de 2026, 20_37_00.png**
- `easyappicon-icons-1788651440281/` ← export do [EasyAppIcon](https://easyappicon.com/)

Depois rode na raiz do repo:

```bash
./scripts/import_branding.sh
```

O script copia logo + ícones, gera `app/assets/branding/`, instala mipmaps Android, cria plataforma iOS (se ausente) com `AppIcon.appiconset`, e regenera o splash nativo.

## Pendente

- **Screenshots** (≥4): capturar do emulador/dispositivo com o app rodando (Home, Leitor, Busca, Atualizações)

## Referências

- [brand.md](../brand.md) — diretrizes visuais
- [listing-pt-BR.md](listing-pt-BR.md) — título, descrições e checklist Play Console
- [procedures/07-publicar-play-store.md](../procedures/07-publicar-play-store.md) — fluxo de publicação
