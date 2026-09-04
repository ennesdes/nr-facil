# Assets da Play Store

Arquivos para upload na Play Console (item 37 do [todo.md](../todo.md)).

## Arquivos

| Arquivo | Dimensão | Uso |
|---------|----------|-----|
| `play_store_icon_512.png` | 512×512 | Presença na loja → Ícone do app |
| `feature_graphic_1024x500.png` | 1024×500 | Presença na loja → Gráfico de recursos |

## Regenerar

### Opção recomendada: geração por IA

Os PNGs atuais foram gerados com a ferramenta de imagem do Cursor e pós-processados (resize + chroma key no foreground). Prompts de referência:

**Ícone (1:1):** usar a feature graphic como `reference_image_paths` e pedir o mesmo mark da esquerda (NR ligado + 3 linhas iguais). Evitar gerar ícone isolado sem referência — o estilo diverge.

**Foreground (1:1):** mesmo mark em branco/cinza sobre preto puro (chroma key → transparência).

**Feature graphic (16:9 → crop 1024×500):** fundo `#FAFBFC`, ícone à esquerda, wordmark "NR Fácil" + tagline à direita. Esta é a referência visual mestre do mark.

Após gerar, processar e copiar:

```bash
# Ajuste os paths dos PNGs gerados no script abaixo, depois:
python3 scripts/postprocess_branding.py
cd app && fvm dart run flutter_launcher_icons && fvm dart run flutter_native_splash:create
```

### Opção fallback: Pillow (prototipagem)

```bash
source .venv/bin/activate
pip install -r scripts/requirements-dev.txt
python3 scripts/generate_branding.py
```

Qualidade inferior — usar só para testes rápidos de layout.

## Pendente

- **Screenshots** (≥4): capturar do emulador/dispositivo com o app rodando (Home, Leitor, Busca, Atualizações)

## Referências

- [brand.md](../brand.md) — diretrizes visuais
- [procedures/07-publicar-play-store.md](../procedures/07-publicar-play-store.md) — ficha da loja
