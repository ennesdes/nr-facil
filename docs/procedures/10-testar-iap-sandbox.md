# Procedure 10 — Testar IAP (sandbox)

## Objetivo

Testar compra `remove_ads_lifetime` (R$ 9,90) antes de publicar.

## Pré-requisitos

- App no teste interno da Play Console
- Produto IAP criado no Play Console
- Conta Google adicionada como **testador de licença**

## Passo a passo

### 1. Criar produto no Play Console

1. Play Console → app → **Monetização → Produtos no app**
2. **Criar produto**
3. ID: `remove_ads_lifetime` (deve bater com o código Flutter)
4. Nome: Remover anúncios
5. Descrição: Remove banners permanentemente
6. Preço: R$ 9,90 (ou faixa desejada)
7. Tipo: **Compra única** (não assinatura)
8. Ativar produto

### 2. Configurar testadores

1. Play Console → **Configurações → Testadores de licença**
2. Adicione seu e-mail Gmail
3. Salve

### 3. Instalar via teste interno

- Use o link de teste interno (não APK sideload)
- IAP só funciona com app assinado pela Play

### 4. Testar fluxo

1. Abra app → Ajustes → Remover anúncios
2. Inicie compra
3. Confirme (testadores veem "[Teste]" ou preço R$ 0,00 em alguns casos)
4. Verifique: banners somem
5. Feche e reabra app — anúncios continuam off
6. Teste **Restaurar compras** (reinstale app)

### 5. IDs no código

Produto no Flutter:

```dart
const String kRemoveAdsProductId = 'remove_ads_lifetime';
```

## Troubleshooting

| Problema | Solução |
|----------|---------|
| Produto não encontrado | Aguarde 24h após criar; confira ID exato |
| Compra falha | App deve vir do teste interno; conta deve ser testador |
| Ads voltam após reinstalar | Implementar `restorePurchases()` no startup |
| Cobrança real em teste | Use conta de testador de licença |

## Próximo passo

→ Item 40 do [todo.md](../../todo.md) — produção
