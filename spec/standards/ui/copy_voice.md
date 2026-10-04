# Copy e tom de voz — NR Fácil

> Strings de UI em **pt_BR**. Código em inglês. Marca: [`../../../docs/brand.md`](../../../docs/brand.md).

## Quem é o app

Consultor de SST acessível: claro, direto, respeitoso. Ajuda a **consultar** normas oficiais e checklist prático — **não** substitui o MTE nem um profissional habilitado.

## Pronome e português

- **você / seu / sua**
- Português do Brasil
- Evitar jargão sem contexto; siglas de NR podem aparecer com expansão na primeira menção quando couber

## Tom

| Fazer | Evitar |
|-------|--------|
| Explicar o próximo passo ("Baixar", "Ver na norma") | Tom burocrático ou alarmista |
| Erros humanos (`user_messages.dart`) | Códigos técnicos expostos |
| Disclaimer de não-oficialidade onde exigido | Sugerir que o app é do governo |

## Vocabulário fixo

| Termo | Uso |
|-------|-----|
| **norma** / **NR** | Norma Regulamentadora |
| **Baixar** | Sync offline de uma NR |
| **Atualizações** | Inbox de normas para revisar (sino) |
| **Para revisar** | Badge/lista quando `hasUpdate` |
| **Marcar como revisada** | Concluir revisão do diff sem abrir item no texto |
| **Abrir norma** | Leitor sem concluir revisão |
| **Ocultar aviso** | Dispensar card na home (não revisa) |
| **Checklist** | Conformidade por empresa (NR-28 e itens) |
| **Ajustes** | Tema, verificar atualizações, legal |

## Legal (leitor e sobre)

Texto base do disclaimer — ver [`../../capabilities/reader/01-leitor.md`](../../capabilities/reader/01-leitor.md) e `ReaderFooter`.

## Checklist

Copy específico em `app/lib/features/compliance/compliance_copy.dart` — manter alinhado a esta seção ao alterar strings.

## CTAs

- Infinitivo curto: "Baixar", "Verificar atualizações", "Continuar leitura"
- Confirmações destrutivas: verbo + objeto ("Remover favorito")
