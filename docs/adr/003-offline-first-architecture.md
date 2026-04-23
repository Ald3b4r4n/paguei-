# ADR-003: Arquitetura Offline-First

**Status**: Aceito
**Data**: 2026-04-19
**Decisores**: Equipe Paguei?

---

## Contexto

Usuários brasileiros frequentemente operam em ambientes com conectividade intermitente ou ausente (metrô, zonas rurais, dados móveis limitados). Dados financeiros pessoais são críticos demais para depender de disponibilidade de rede.

---

## Decisão

O Drift (SQLite local) é o **source of truth primário**. A rede é aditiva e nunca bloqueia o acesso aos dados.

---

## Princípios de Implementação

```
[Usuário] → [Presentation] → [Application/UseCases]
                                      ↓
                              [Domain/Repository Interface]
                                      ↓
                              [Data/RepositoryImpl]
                                      ↓
                         ┌────────────┴────────────┐
                     [Local/Drift]           [Remote/API] (futuro)
                         ↑                         |
                    source of truth          sync aditivo
```

### Regras

1. **Local sempre primeiro**: Toda query lê do Drift. A camada remote é consultada apenas para sync.
2. **Sync não bloqueia UI**: Operações de sync são disparadas em background sem loading global.
3. **Conflito resolvido pelo local**: Em conflitos, a versão local prevalece (usuário tem controle total).
4. **Falha de rede não é erro**: `NetworkFailure` é tratado com retry silencioso, não com tela de erro.
5. **Domain não conhece rede**: As interfaces de repositório no domínio não expõem conceitos de sync.

---

## Preparação para Cloud Sync (Fase 6+)

O schema Drift já inclui `createdAt` e `updatedAt` em todas as entidades mutáveis — campo necessário para sincronização por timestamp. A adição de sync requerirá apenas:
- Nova implementação de `RemoteDataSource` na camada `data/`
- Lógica de merge no `RepositoryImpl`
- **Nenhuma alteração em `domain/` ou `application/`**

---

## Consequências

- App funciona 100% offline sem degradação de funcionalidade core.
- `NetworkFailure` nunca propaga para a UI como erro fatal.
- `AppDatabase` é o único ponto de persistência na Fase 1–5.
- Backup local é a estratégia primária de proteção de dados na Fase 7.
