# Procedure 02 — Conta Google Play Console

## Objetivo

Criar conta de desenvolvedor para publicar o NR Fácil na Play Store.

## Pré-requisitos

- Conta Google pessoal ou corporativa
- Cartão de crédito (taxa única ~US$ 25)
- Documento de identidade (pode ser solicitado na verificação)

## Passo a passo

### 1. Acessar o Play Console

1. Abra https://play.google.com/console
2. Faça login com sua conta Google

### 2. Criar conta de desenvolvedor

1. Clique em **Criar conta de desenvolvedor** (se for primeira vez)
2. Aceite o **Contrato de distribuição**
3. Pague a taxa de registro (~US$ 25, pagamento único)
4. Preencha nome do desenvolvedor (aparece na loja)
5. E-mail e telefone de contato

### 3. Verificação de identidade

O Google pode pedir:

- Foto do documento
- Comprovante de endereço  
Aguarde aprovação (pode levar alguns dias).

### 4. Criar o app (pode ser na Fase 5)

1. No painel: **Criar app**
2. Nome: **NR Fácil**
3. Idioma padrão: Português (Brasil)
4. Tipo: **App** / **Jogo**: App
5. Gratuito ou pago: **Gratuito** (monetização via ads + IAP)

### 5. Anotar informações

Guarde em local seguro (não no git):

- Package name: `com.douglasennes.nrfacil` (definir no Flutter)
- E-mail da conta desenvolvedor

## O que NÃO fazer agora

- Upload do AAB (Fase 5)
- Configurar IAP (Fase 5)
- Publicar em produção antes dos testes internos

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Conta suspensa | Verifique e-mail do Google; responda solicitações de verificação |
| Pagamento recusado | Tente outro cartão ou contate suporte Play |
| Nome de desenvolvedor já usado | Escolha variação (ex.: "Douglas Ennes Apps") |

## Próximo passo

→ Pode adiar criação do app até Fase 5. Continue com item 05 do [todo.md](../../todo.md) (URLs MTE).
