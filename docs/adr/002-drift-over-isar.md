# ADR-002: Drift como banco de dados local

**Status**: Aceito
**Data**: 2026-04-19
**Decisores**: Equipe Paguei?

---

## Contexto

O Paguei? é offline-first e requer um banco de dados local que suporte:
- Migrações versionadas e type-safe
- Queries com type-safety em tempo de compilação
- Streams reativos para UI
- Exportação de dados (CSV, backup)
- Criptografia em repouso (SQLCipher)

Alternativas avaliadas: **Drift (moor) 2.x**, **Isar 3.x**, **Hive 4.x**, **sqflite 2.x**.

---

## Decisão

Adotamos **drift ^2.32.1** com **sqlite3_flutter_libs**.

---

## Justificativa

### Isar está abandonado

A issue [#1689](https://github.com/isar/isar/issues/1689) ("Isar is dead, long live Isar") confirma que o autor original abandonou o projeto. O core em Rust torna forks de comunidade impraticáveis. **Isar não pode ser usado em produção.**

### Hive está estagnado

Hive 4.x não tem migrações nativas. Para um app de finanças onde a integridade de dados e a evolução do schema são requisitos críticos, Hive é inadequado.

### sqflite requer trabalho manual

sqflite é um wrapper fino sobre SQLite sem ORM, sem type-safety e sem sistema de migrações integrado. Toda migração seria escrita como SQL raw, sem validação em compilação.

### Drift entrega tudo que precisamos

| Critério | Drift | Isar | Hive | sqflite |
|---|---|---|---|---|
| Status | ✅ Ativo | ❌ Abandonado | ⚠️ Estagnado | ✅ Ativo |
| Migrações tipadas | ✅ | Parcial | ❌ | Manual |
| Type-safety em queries | ✅ | ✅ | ✅ | ❌ |
| Streams reativos | ✅ | ✅ | ✅ | ❌ |
| Criptografia (SQLCipher) | ✅ | ✅ | Parcial | Plugin externo |
| Backup / Export SQL | ✅ | Parcial | ❌ | ✅ |

---

## Consequências

- Geração de código obrigatória: `dart run build_runner build` antes de qualquer compilação.
- Schema v1 inclui todas as 10 entidades do data-model.md.
- Migrações futuras adicionadas em `AppDatabase._runMigration()` numeradas sequencialmente.
- Testes de migração OBRIGATÓRIOS para toda mudança de schema.
- `PRAGMA foreign_keys = ON` e `PRAGMA journal_mode = WAL` configurados no `beforeOpen`.
