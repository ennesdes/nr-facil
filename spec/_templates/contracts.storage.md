# Fragmento — contrato de persistência

Use dentro da seção 5.1 de uma demanda ou capability quando houver storage.

| Chave (`StorageKeys`) | Shape JSON | Migração / default | Dono service |
|-----------------------|------------|--------------------|--------------|
| | | | |

- `fromMap` sempre defensivo — sem crash com dado corrompido.
- Mudança de formato → teste unitário em `app/test/` + nota em `spec/standards/testing/change_impact.md`.
