# Procedure 03 — Mapear URLs MTE

## Objetivo

Coletar links oficiais dos PDFs das NRs no portal do MTE para `scripts/nr_sources.json`.

## Pré-requisitos

- Navegador com internet
- Arquivo `scripts/nr_sources.json` no projeto

## Importante

- **Não existe API** do MTE — só links públicos para PDF
- URLs **não seguem padrão fixo** — cada NR tem link próprio
- Use sempre o PDF **vigente** (não versão futura nem revogada)

## Passo a passo

### 1. Abrir página oficial

Acesse:  
https://www.gov.br/trabalho-e-emprego/pt-br/acesso-a-informacao/participacao-social/conselhos-e-orgaos-colegiados/comissao-tripartite-partitaria-permanente/normas-regulamentadora/normas-regulamentadoras-vigentes

### 2. Para cada NR do MVP (comece com 5)

Prioridade inicial: **NR-01, NR-06, NR-10, NR-17, NR-18**

1. Clique na NR na lista (ex.: NR-6 — EPI)
2. Na página da NR, localize o link do **PDF vigente**
3. Clique com botão direito no PDF → **Copiar endereço do link**
4. Cole no `scripts/nr_sources.json`

### 3. Formato do JSON

Edite `scripts/nr_sources.json`:

```json
{
  "nr-01": {
    "title": "Disposições Gerais e GRO",
    "pdf_url": "https://www.gov.br/trabalho-e-emprego/.../arquivo.pdf",
    "revogada": false
  },
  "nr-06": {
    "title": "Equipamento de Proteção Individual - EPI",
    "pdf_url": "https://www.gov.br/trabalho-e-emprego/.../nr-06-atualizada-2025.pdf",
    "revogada": false
  }
}
```

### 4. NRs revogadas

NR-2 e NR-27 estão revogadas. Se incluir, marque:

```json
"nr-02": {
  "title": "Inspeção Prévia",
  "revogada": true
}
```

Sem `pdf_url` — o pipeline não baixa.

### 5. Múltiplas versões (ex.: NR-01)

Se a página mostrar duas versões (vigente hoje vs. futura):

- Use o PDF **vigente hoje**
- Opcional: campo `"vigente_ate": "2026-05-25"` para lembrete

### 6. Validar link

Abra o URL no navegador — deve baixar/abrir um PDF, não página HTML de erro.

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Link 404 | A página da NR mudou; busque PDF na página índice novamente |
| Dois PDFs na mesma página | Escolha o marcado como vigente |
| PDF abre no navegador sem URL clara | Use "Copiar link" no botão de download, não o viewer |

## Próximo passo

→ Item 08 do [todo.md](../../todo.md) — rodar `python scripts/convert_nr.py --nr nr-06`
